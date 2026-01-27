module Payments
  module Webhooks
    class StripeIngestor
      def ingest!(provider_event_id:, provider_event_type:, occurred_at:, payload:)
        payload ||= {}

        entity_type = normalized_entity_type(provider_event_type)
        event_type = normalized_event_type(provider_event_type)

        obj = payload.dig('data', 'object') || {}

        payment_attempt = payment_attempt_for_payload(obj) if entity_type == :payment_attempt
        payment_refund = payment_refund_for_payload(provider_event_type, obj) if entity_type == :refund

        amount_cents = amount_cents_for_payload(provider_event_type, obj)
        currency = currency_for_payload(obj)

        LedgerEvent.create!(
          provider: :stripe,
          provider_event_id: provider_event_id.to_s,
          provider_event_type: provider_event_type.to_s,
          entity_type: entity_type,
          entity_id: (payment_attempt || payment_refund)&.id,
          event_type: event_type,
          amount_cents: amount_cents,
          currency: currency,
          raw_event_payload: payload,
          occurred_at: occurred_at,
        )

        if payment_attempt && event_type == :succeeded
          payment_attempt.update!(status: :succeeded)
        end

        if payment_refund && event_type == :refunded
          payment_refund.update!(status: :succeeded)
        end

        handle_payment_effects!(provider_event_type: provider_event_type.to_s, obj: obj)
      rescue ActiveRecord::RecordNotUnique
      end

      private

      def normalized_entity_type(provider_event_type)
        case provider_event_type.to_s
        when 'charge.refunded'
          :refund
        when /^refund\./
          :refund
        else
          :payment_attempt
        end
      end

      def normalized_event_type(provider_event_type)
        case provider_event_type.to_s
        when 'checkout.session.completed', 'payment_intent.succeeded'
          :succeeded
        when 'charge.refunded'
          :refunded
        when /^refund\./
          :refunded
        else
          :created
        end
      end

      def amount_cents_for_payload(provider_event_type, obj)
        case provider_event_type.to_s
        when 'checkout.session.completed'
          obj['amount_total']
        when 'payment_intent.succeeded'
          obj['amount_received'] || obj['amount']
        when 'charge.refunded'
          obj['amount_refunded']
        when /^refund\./
          obj['amount']
        else
          nil
        end
      rescue StandardError
        nil
      end

      def currency_for_payload(obj)
        c = obj['currency']
        return nil if c.blank?

        c.to_s.upcase
      rescue StandardError
        nil
      end

      def payment_attempt_for_payload(obj)
        md = obj['metadata'] || {}
        payment_attempt_id = md['payment_attempt_id'] || md[:payment_attempt_id]
        return PaymentAttempt.find_by(id: payment_attempt_id) if payment_attempt_id.present?

        provider_payment_id = obj['id'].to_s
        return nil if provider_payment_id.blank?

        PaymentAttempt.find_by(provider: :stripe, provider_payment_id: provider_payment_id)
      rescue StandardError
        nil
      end

      def payment_refund_for_payload(provider_event_type, obj)
        case provider_event_type.to_s
        when /^refund\./
          PaymentRefund.find_by(provider: :stripe, provider_refund_id: obj['id'].to_s)
        else
          nil
        end
      rescue StandardError
        nil
      end

      def handle_payment_effects!(provider_event_type:, obj:)
        case provider_event_type
        when 'checkout.session.completed'
          handle_checkout_session_completed(obj)
        when 'payment_intent.succeeded'
          handle_payment_intent_succeeded(obj)
        end
      end

      def handle_payment_intent_succeeded(obj)
        order_id = extract_order_id(obj)
        return if order_id.blank?

        ordr = Ordr.find_by(id: order_id)
        return unless ordr

        split_payment_id = extract_split_payment_id(obj)
        pi_id = obj['id'].to_s

        if split_payment_id.present?
          mark_split_payment_succeeded(ordr: ordr, split_payment_id: split_payment_id, checkout_session_id: nil, payment_intent_id: pi_id)
          emit_paid_if_settled!(ordr: ordr, idempotency_key: "stripe:split_paid:#{ordr.id}", external_ref: pi_id)
          emit_closed_if_paid!(ordr: ordr, idempotency_key: "stripe:split_closed:#{ordr.id}", external_ref: pi_id)
          OrderEventProjector.project!(ordr.id)
          broadcast_state(ordr.reload)
          return
        end

        unless OrderEvent.where(ordr_id: ordr.id, event_type: 'paid').exists?
          emit_paid!(ordr: ordr, idempotency_key: "stripe:payment_intent:#{pi_id}", external_ref: pi_id)
        end

        emit_closed_if_paid!(ordr: ordr, idempotency_key: "stripe:payment_intent_closed:#{pi_id}", external_ref: pi_id)

        OrderEventProjector.project!(ordr.id)
        broadcast_state(ordr.reload)
      end

      def handle_checkout_session_completed(obj)
        order_id = extract_order_id(obj)
        return if order_id.blank?

        ordr = Ordr.find_by(id: order_id)
        return unless ordr

        checkout_id = obj['id'].to_s
        pi_id = obj['payment_intent'].to_s.presence

        split_payment_id = extract_split_payment_id(obj)

        if split_payment_id.present?
          mark_split_payment_succeeded(ordr: ordr, split_payment_id: split_payment_id, checkout_session_id: checkout_id, payment_intent_id: pi_id)
          emit_paid_if_settled!(ordr: ordr, idempotency_key: "stripe:split_paid:#{ordr.id}", external_ref: checkout_id)
          emit_closed_if_paid!(ordr: ordr, idempotency_key: "stripe:split_closed:#{ordr.id}", external_ref: checkout_id)
        else
          unless OrderEvent.where(ordr_id: ordr.id, event_type: 'paid').exists?
            emit_paid!(ordr: ordr, idempotency_key: "stripe:checkout_session:#{checkout_id}", external_ref: checkout_id)
          end
          emit_closed_if_paid!(ordr: ordr, idempotency_key: "stripe:checkout_session_closed:#{checkout_id}", external_ref: checkout_id)
        end

        OrderEventProjector.project!(ordr.id)
        broadcast_state(ordr.reload)
      end

      def extract_order_id(obj)
        md = obj['metadata'] || {}
        md['order_id'] || md[:order_id] || md['orderId'] || md[:orderId] || obj['client_reference_id']
      rescue StandardError
        nil
      end

      def extract_split_payment_id(obj)
        md = obj['metadata'] || {}
        md['ordr_split_payment_id'] || md[:ordr_split_payment_id]
      rescue StandardError
        nil
      end

      def mark_split_payment_succeeded(ordr:, split_payment_id:, checkout_session_id:, payment_intent_id:)
        sp = ordr.ordr_split_payments.find_by(id: split_payment_id)
        return unless sp

        updates = {
          status: OrdrSplitPayment.statuses['succeeded'],
        }
        updates[:stripe_checkout_session_id] = checkout_session_id if checkout_session_id.present?
        updates[:stripe_payment_intent_id] = payment_intent_id if payment_intent_id.present?

        sp.update!(updates)
      end

      def emit_paid_if_settled!(ordr:, idempotency_key:, external_ref:)
        return if OrderEvent.where(ordr_id: ordr.id, event_type: 'paid').exists?

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
            provider: 'stripe',
            external_ref: external_ref.to_s,
          },
        )
      end

      def emit_closed_if_paid!(ordr:, idempotency_key:, external_ref:)
        return if OrderEvent.where(ordr_id: ordr.id, event_type: 'closed').exists?

        paid = OrderEvent.where(ordr_id: ordr.id, event_type: 'paid').exists?
        return unless paid

        OrderEvent.emit!(
          ordr: ordr,
          event_type: 'closed',
          entity_type: 'order',
          entity_id: ordr.id,
          source: 'webhook',
          idempotency_key: idempotency_key,
          payload: {
            provider: 'stripe',
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
