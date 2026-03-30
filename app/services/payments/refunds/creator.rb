module Payments
  module Refunds
    class Creator
      def create_full_refund!(payment_attempt:)
        raise ArgumentError, 'payment_attempt is required' if payment_attempt.nil?

        # Guard against duplicate refunds from admin double-clicks or job retries.
        existing = PaymentRefund.find_by(payment_attempt: payment_attempt, status: %i[processing succeeded])
        if existing
          Rails.logger.warn("[Payments::Refunds::Creator] Refund already exists for payment_attempt #{payment_attempt.id}: refund ##{existing.id} status=#{existing.status}")
          return existing
        end

        refund = PaymentRefund.create!(
          payment_attempt: payment_attempt,
          ordr: payment_attempt.ordr,
          restaurant: payment_attempt.restaurant,
          provider: payment_attempt.provider,
          amount_cents: payment_attempt.amount_cents,
          currency: payment_attempt.currency,
          status: :processing,
        )

        adapter = provider_adapter(payment_attempt.provider, payment_attempt: payment_attempt)
        created = adapter.create_full_refund!(payment_attempt: payment_attempt)

        refund.update!(
          provider_refund_id: created[:refund_id].to_s.presence,
          provider_response_payload: created[:raw] || {},
          status: :succeeded,
        )

        refund
      rescue StandardError => e
        refund.update!(status: :failed) if refund&.persisted?
        raise e
      end

      private

      def provider_adapter(provider, payment_attempt: nil)
        case provider.to_sym
        when :stripe
          Payments::Providers::StripeAdapter.new
        when :square
          restaurant = payment_attempt&.restaurant
          raise ArgumentError, 'Square refund requires a restaurant on the payment attempt' unless restaurant

          Payments::Providers::SquareAdapter.new(restaurant: restaurant)
        else
          raise ArgumentError, "Unsupported provider: #{provider}"
        end
      end
    end
  end
end
