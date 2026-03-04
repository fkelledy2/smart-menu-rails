# frozen_string_literal: true

module Payments
  module Webhooks
    # Processes Square webhook events, mirroring StripeIngestor structure.
    #
    # Supported events:
    #   payment.completed  → mark PaymentAttempt succeeded, emit paid OrderEvent
    #   payment.updated    → update PaymentAttempt status
    #   payment.failed     → mark PaymentAttempt failed
    #   refund.created     → record refund
    #   refund.updated     → update refund status
    #   oauth.authorization.revoked → disconnect restaurant
    class SquareIngestor
      def ingest!(provider_event_id:, provider_event_type:, occurred_at:, payload:)
        payload ||= {}

        entity_type = normalized_entity_type(provider_event_type)
        event_type = normalized_event_type(provider_event_type)

        obj = payload.dig('data', 'object') || payload.dig('data') || {}

        payment_attempt = payment_attempt_for_payload(obj) if entity_type == :payment_attempt
        payment_refund = payment_refund_for_payload(obj) if entity_type == :refund

        amount_cents = amount_cents_for_payload(obj)
        currency = currency_for_payload(obj)

        normalized = Payments::NormalizedEvent.new(
          provider: :square,
          provider_event_id: provider_event_id,
          provider_event_type: provider_event_type,
          occurred_at: occurred_at,
          entity_type: entity_type,
          entity_id: (payment_attempt || payment_refund)&.id,
          event_type: event_type,
          amount_cents: amount_cents,
          currency: currency,
          metadata: extract_metadata(obj),
        )

        unless provider_event_type.to_s == 'oauth.authorization.revoked'
          Payments::Ledger.append!(
            **normalized.ledger_attributes,
            raw_event_payload: payload,
          )
        end

        handle_event!(
          provider_event_type: provider_event_type.to_s,
          event_type: event_type,
          payment_attempt: payment_attempt,
          payment_refund: payment_refund,
          obj: obj,
        )
      rescue ActiveRecord::RecordNotUnique => e
        Rails.logger.debug { "[SquareIngestor] RecordNotUnique ignored provider_event_id=#{provider_event_id}: #{e.message}" }
        nil
      end

      private

      def normalized_entity_type(provider_event_type)
        case provider_event_type.to_s
        when /^refund\./
          :refund
        when /^payment\./
          :payment_attempt
        else
          :payment_attempt
        end
      end

      def normalized_event_type(provider_event_type)
        case provider_event_type.to_s
        when 'payment.completed'
          :succeeded
        when 'payment.updated'
          :created
        when 'payment.failed'
          :failed
        when 'refund.created', 'refund.updated'
          :refunded
        when 'oauth.authorization.revoked'
          :failed
        else
          :created
        end
      end

      def amount_cents_for_payload(obj)
        payment = obj['payment'] || obj
        money = payment.dig('amount_money') || payment.dig('total_money')
        money&.fetch('amount', nil)&.to_i
      rescue StandardError
        nil
      end

      def currency_for_payload(obj)
        payment = obj['payment'] || obj
        money = payment.dig('amount_money') || payment.dig('total_money')
        c = money&.fetch('currency', nil)
        c&.to_s&.upcase
      rescue StandardError
        nil
      end

      def extract_metadata(obj)
        payment = obj['payment'] || obj
        payment['reference_id'].present? ? { 'reference_id' => payment['reference_id'] } : {}
      rescue StandardError
        {}
      end

      def payment_attempt_for_payload(obj)
        payment = obj['payment'] || obj
        payment_id = payment['id'].to_s
        return nil if payment_id.blank?

        # Try by provider_payment_id first
        attempt = PaymentAttempt.find_by(provider: :square, provider_payment_id: payment_id)
        return attempt if attempt

        # Try by idempotency_key
        idem_key = payment['idempotency_key'] || payment.dig('reference_id')
        return nil if idem_key.blank?

        PaymentAttempt.find_by(idempotency_key: idem_key)
      rescue StandardError
        nil
      end

      def payment_refund_for_payload(obj)
        refund = obj['refund'] || obj
        refund_id = refund['id'].to_s
        return nil if refund_id.blank?

        PaymentRefund.find_by(provider: :square, provider_refund_id: refund_id)
      rescue StandardError
        nil
      end

      def handle_event!(provider_event_type:, event_type:, payment_attempt:, payment_refund:, obj:)
        case provider_event_type
        when 'payment.completed'
          handle_payment_completed(payment_attempt: payment_attempt, obj: obj)
        when 'payment.updated'
          handle_payment_updated(payment_attempt: payment_attempt, obj: obj)
        when 'payment.failed'
          handle_payment_failed(payment_attempt: payment_attempt, obj: obj)
        when 'refund.created', 'refund.updated'
          handle_refund(payment_refund: payment_refund, obj: obj)
        when 'oauth.authorization.revoked'
          handle_oauth_revoked(obj: obj)
        end
      end

      def handle_payment_completed(payment_attempt:, obj:)
        return unless payment_attempt

        payment_attempt.update!(status: :succeeded)

        order_id = extract_order_id(obj)
        return if order_id.blank?

        ordr = Ordr.find_by(id: order_id)
        return unless ordr

        payment = obj['payment'] || obj
        payment_id = payment['id'].to_s
        split_payment_id = extract_split_payment_id(obj)

        if split_payment_id.present?
          mark_split_payment_succeeded(ordr: ordr, split_payment_id: split_payment_id, payment_id: payment_id)
          emit_paid_if_settled!(ordr: ordr, idempotency_key: "square:split_paid:#{ordr.id}", external_ref: payment_id)
          emit_closed_if_paid!(ordr: ordr, idempotency_key: "square:split_closed:#{ordr.id}", external_ref: payment_id)
        else
          unless OrderEvent.exists?(ordr_id: ordr.id, event_type: 'paid')
            emit_paid!(ordr: ordr, idempotency_key: "square:payment:#{payment_id}", external_ref: payment_id)
          end
          emit_closed_if_paid!(ordr: ordr, idempotency_key: "square:payment_closed:#{payment_id}", external_ref: payment_id)
        end

        OrderEventProjector.project!(ordr.id)
        broadcast_state(ordr.reload)
      end

      def handle_payment_updated(payment_attempt:, obj:)
        return unless payment_attempt

        payment = obj['payment'] || obj
        square_status = payment['status'].to_s.downcase
        mapped = map_payment_status(square_status)
        payment_attempt.update!(status: mapped) if mapped.present?
      end

      def handle_payment_failed(payment_attempt:, obj:)
        return unless payment_attempt

        payment_attempt.update!(status: :failed)
      end

      def handle_refund(payment_refund:, obj:)
        return unless payment_refund

        refund = obj['refund'] || obj
        square_status = refund['status'].to_s.downcase
        case square_status
        when 'completed'
          payment_refund.update!(status: :succeeded)
        when 'failed'
          payment_refund.update!(status: :failed)
        when 'pending'
          payment_refund.update!(status: :processing)
        end
      end

      def handle_oauth_revoked(obj:)
        merchant_id = obj['merchant_id'].to_s
        return if merchant_id.blank?

        restaurant = Restaurant.find_by(square_merchant_id: merchant_id)
        return unless restaurant

        restaurant.update!(
          payment_provider_status: :disconnected,
          square_oauth_revoked_at: Time.current,
        )

        account = ProviderAccount.find_by(restaurant: restaurant, provider: :square)
        account&.update!(status: :disabled, disconnected_at: Time.current)

        Rails.logger.warn("[SquareIngestor] OAuth revoked for restaurant_id=#{restaurant.id} merchant_id=#{merchant_id}")
      end

      def map_payment_status(square_status)
        case square_status
        when 'completed' then :succeeded
        when 'approved'  then :processing
        when 'pending'   then :requires_action
        when 'failed', 'canceled' then :failed
        else nil
        end
      end

      def extract_order_id(obj)
        payment = obj['payment'] || obj
        ref = payment['reference_id']
        return ref if ref.present?

        note = payment['note'].to_s
        match = note.match(/order[_:]?(\d+)/i)
        match&.captures&.first
      rescue StandardError
        nil
      end

      def extract_split_payment_id(obj)
        payment = obj['payment'] || obj
        note = payment['note'].to_s
        match = note.match(/split[_:]?(\d+)/i)
        match&.captures&.first
      rescue StandardError
        nil
      end

      def mark_split_payment_succeeded(ordr:, split_payment_id:, payment_id:)
        sp = ordr.ordr_split_payments.find_by(id: split_payment_id)
        return unless sp

        updates = { status: OrdrSplitPayment.statuses['succeeded'] }
        updates[:provider_payment_id] = payment_id if payment_id.present?
        sp.update!(updates)
      end

      def emit_paid_if_settled!(ordr:, idempotency_key:, external_ref:)
        return if OrderEvent.exists?(ordr_id: ordr.id, event_type: 'paid')

        has_splits = ordr.ordr_split_payments.exists?
        return emit_paid!(ordr: ordr, idempotency_key: idempotency_key, external_ref: external_ref) unless has_splits

        unsettled = ordr.ordr_split_payments.where.not(status: OrdrSplitPayment.statuses['succeeded']).exists?
        return if unsettled

        emit_paid!(ordr: ordr, idempotency_key: idempotency_key, external_ref: external_ref)
      end

      def emit_paid!(ordr:, idempotency_key:, external_ref:)
        OrderEvent.emit!(
          ordr: ordr,
          event_type: 'paid',
          entity_type: 'payment',
          entity_id: ordr.id,
          source: 'webhook',
          idempotency_key: idempotency_key,
          payload: {
            provider: 'square',
            external_ref: external_ref.to_s,
          },
        )
      end

      def emit_closed_if_paid!(ordr:, idempotency_key:, external_ref:)
        return if OrderEvent.exists?(ordr_id: ordr.id, event_type: 'closed')
        return unless OrderEvent.exists?(ordr_id: ordr.id, event_type: 'paid')

        OrderEvent.emit!(
          ordr: ordr,
          event_type: 'closed',
          entity_type: 'order',
          entity_id: ordr.id,
          source: 'webhook',
          idempotency_key: idempotency_key,
          payload: {
            provider: 'square',
            external_ref: external_ref.to_s,
          },
        )
      end

      def broadcast_state(ordr)
        menu = ordr.menu
        restaurant = ordr.restaurant
        tablesetting = ordr.tablesetting

        payload = SmartmenuState.for_context(
          menu: menu,
          restaurant: restaurant,
          tablesetting: tablesetting,
          open_order: ordr,
          ordrparticipant: nil,
          menuparticipant: nil,
          session_id: 'webhook',
        )

        ActionCable.server.broadcast("ordr_#{ordr.id}_channel", { state: payload })

        begin
          smartmenu = Smartmenu.find_by(menu_id: menu.id, tablesetting_id: tablesetting.id)
          if smartmenu&.slug.present?
            ActionCable.server.broadcast("ordr_#{smartmenu.slug}_channel", { state: payload })
          end
        rescue StandardError
          nil
        end
      end
    end
  end
end
