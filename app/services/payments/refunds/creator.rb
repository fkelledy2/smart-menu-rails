module Payments
  module Refunds
    class Creator
      def create_full_refund!(payment_attempt:)
        raise ArgumentError, 'payment_attempt is required' if payment_attempt.nil?

        refund = PaymentRefund.create!(
          payment_attempt: payment_attempt,
          ordr: payment_attempt.ordr,
          restaurant: payment_attempt.restaurant,
          provider: payment_attempt.provider,
          amount_cents: payment_attempt.amount_cents,
          currency: payment_attempt.currency,
          status: :processing,
        )

        adapter = provider_adapter(payment_attempt.provider)
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

      def provider_adapter(provider)
        case provider.to_sym
        when :stripe
          Payments::Providers::StripeAdapter.new
        else
          raise ArgumentError, "Unsupported provider: #{provider}"
        end
      end
    end
  end
end
