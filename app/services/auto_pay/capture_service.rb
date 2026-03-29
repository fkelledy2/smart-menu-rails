module AutoPay
  # Validates preconditions, calls Payments::Orchestrator, updates Ordr,
  # enqueues receipt delivery, and broadcasts result to staff via ActionCable.
  #
  # Usage:
  #   result = AutoPay::CaptureService.new(ordr: ordr).call
  #   result.success? # => true / false
  #   result.error    # => String or nil
  class CaptureService
    Result = Struct.new(:success, :error, keyword_init: true) do
      def success? = success
      def failure? = !success
    end

    AUTO_PAY_STATUSES = %w[pending succeeded failed].freeze

    def initialize(ordr:)
      @ordr = ordr
    end

    def call
      return already_captured_result if already_captured?
      return precondition_failure('Auto-pay is not enabled') unless @ordr.auto_pay_enabled?
      return precondition_failure('No payment method on file') unless @ordr.payment_on_file?
      return precondition_failure('Order has already been paid') if @ordr.paid? || @ordr.closed?

      # Zero-total edge case: mark paid without charging
      if zero_total?
        mark_paid_without_charge!
        return Result.new(success: true, error: nil)
      end

      attempt_capture
    rescue StandardError => e
      Rails.logger.error("[AutoPay::CaptureService] Unexpected error for ordr=#{@ordr.id}: #{e.class}: #{e.message}")
      handle_failure(e.message)
      Result.new(success: false, error: e.message)
    end

    private

    def already_captured?
      @ordr.auto_pay_status == 'succeeded'
    end

    def already_captured_result
      Rails.logger.info("[AutoPay::CaptureService] ordr=#{@ordr.id} already captured — skipping")
      Result.new(success: true, error: nil)
    end

    def precondition_failure(reason)
      Rails.logger.warn("[AutoPay::CaptureService] ordr=#{@ordr.id} precondition failed: #{reason}")
      Result.new(success: false, error: reason)
    end

    def zero_total?
      @ordr.gross.to_f <= 0
    end

    def gross_cents
      (((@ordr.gross || 0) - (@ordr.tip || 0)) * 100.0).round
    end

    def mark_paid_without_charge!
      @ordr.update!(
        auto_pay_status: 'succeeded',
        auto_pay_attempted_at: Time.current,
      )

      transition_to_paid!
      broadcast_success
      enqueue_receipt

      log_ordr_action(:auto_pay_succeeded)
    end

    def attempt_capture
      @ordr.update!(auto_pay_attempted_at: Time.current)

      currency = @ordr.restaurant.currency.presence || 'USD'
      amount_cents = gross_cents
      payment_method_id = @ordr.payment_method_ref

      orchestrator = Payments::Orchestrator.new(provider: :stripe)
      result = orchestrator.create_and_capture_payment_intent!(
        ordr: @ordr,
        payment_method_id: payment_method_id,
        amount_cents: amount_cents,
        currency: currency,
      )

      handle_success(result)
      Result.new(success: true, error: nil)
    rescue Payments::Orchestrator::CaptureError => e
      handle_failure(e.message)
      Result.new(success: false, error: e.message)
    end

    def handle_success(result)
      @ordr.update!(auto_pay_status: 'succeeded')
      transition_to_paid!
      broadcast_success
      enqueue_receipt
      log_ordr_action(:auto_pay_succeeded)

      Rails.logger.info(
        "[AutoPay::CaptureService] Success ordr=#{@ordr.id} pa_id=#{result[:payment_attempt]&.id}",
      )
    end

    def handle_failure(reason)
      # Truncate non-sensitive reason to avoid leaking raw Stripe messages
      safe_reason = reason.to_s.truncate(500)

      @ordr.update!(
        auto_pay_status: 'failed',
        auto_pay_failure_reason: safe_reason,
        auto_pay_enabled: false,
      )

      broadcast_failure(safe_reason)
      log_ordr_action(:auto_pay_failed)

      Rails.logger.warn("[AutoPay::CaptureService] Failure ordr=#{@ordr.id}: #{safe_reason}")
    end

    def transition_to_paid!
      OrderEvent.emit!(
        ordr: @ordr,
        event_type: 'paid',
        entity_type: 'order',
        entity_id: @ordr.id,
        source: 'auto_pay',
        idempotency_key: "auto_pay_paid:#{@ordr.id}",
        payload: { method: 'auto_pay' },
      )
      OrderEventProjector.project!(@ordr.id)
      @ordr.reload
    rescue StandardError => e
      Rails.logger.warn(
        "[AutoPay::CaptureService] transition_to_paid! failed for ordr=#{@ordr.id}: #{e.class}: #{e.message}",
      )
    end

    def broadcast_success
      payload = {
        event: 'auto_pay_succeeded',
        order_id: @ordr.id,
        status: @ordr.status.to_s,
        timestamp: Time.current.iso8601,
      }

      ActionCable.server.broadcast("kitchen_#{@ordr.restaurant_id}", payload)
      ActionCable.server.broadcast("ordr_#{@ordr.id}_channel", payload)
    rescue StandardError => e
      Rails.logger.warn("[AutoPay::CaptureService] broadcast_success failed: #{e.message}")
    end

    def broadcast_failure(reason)
      payload = {
        event: 'auto_pay_failed',
        order_id: @ordr.id,
        failure_reason: reason,
        timestamp: Time.current.iso8601,
      }

      ActionCable.server.broadcast("kitchen_#{@ordr.restaurant_id}", payload)
      ActionCable.server.broadcast("ordr_#{@ordr.id}_channel", payload)
    rescue StandardError => e
      Rails.logger.warn("[AutoPay::CaptureService] broadcast_failure failed: #{e.message}")
    end

    def enqueue_receipt
      # Receipt delivery requires a known email address.
      # At auto-pay capture time the customer may not have provided one.
      # We attempt to find an email from the ordrparticipant; if unavailable
      # we skip silently — staff can send the receipt manually via the UI.
      recipient_email = participant_email
      return unless recipient_email.present? && Flipper.enabled?(:receipt_email)

      delivery = ReceiptDelivery.create!(
        ordr: @ordr,
        restaurant: @ordr.restaurant,
        delivery_method: 'email',
        recipient_email: recipient_email,
        status: 'pending',
      )

      ReceiptDeliveryJob.perform_later(delivery.id)
    rescue StandardError => e
      Rails.logger.warn(
        "[AutoPay::CaptureService] enqueue_receipt failed for ordr=#{@ordr.id}: #{e.message}",
      )
    end

    def participant_email
      @ordr.ordrparticipants.where(role: 0).find_each do |p|
        return p.email if p.respond_to?(:email) && p.email.present?
      end
      nil
    rescue StandardError
      nil
    end

    def log_ordr_action(action_type)
      participant = @ordr.ordrparticipants.first
      return unless participant

      @ordr.ordractions.create!(
        ordrparticipant_id: participant.id,
        ordr_id: @ordr.id,
        action: action_type,
      )
    rescue StandardError => e
      Rails.logger.warn(
        "[AutoPay::CaptureService] log_ordr_action failed for ordr=#{@ordr.id}: #{e.message}",
      )
    end
  end
end
