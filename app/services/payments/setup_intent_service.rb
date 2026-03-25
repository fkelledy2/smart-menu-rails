require 'stripe'

module Payments
  # Creates a Stripe SetupIntent for capturing a customer's payment method
  # without charging them. Used by Auto Pay & Leave to allow customers to save
  # their card in advance of potential auto-pay capture.
  class SetupIntentService
    class << self
      def create_for_ordr(ordr)
        ensure_api_key!

        setup_intent = Stripe::SetupIntent.create(
          usage: 'off_session',
          metadata: {
            order_id: ordr.id,
            restaurant_id: ordr.restaurant_id,
          },
        )

        setup_intent.client_secret
      end

      private

      def ensure_api_key!
        return if Stripe.api_key.present?

        key = begin
          Rails.application.credentials.dig(:stripe, :secret_key) ||
            Rails.application.credentials.dig(:stripe, :api_key) ||
            Rails.application.credentials.stripe_secret_key
        rescue StandardError
          nil
        end

        key = ENV.fetch('STRIPE_SECRET_KEY', nil) if key.blank?

        raise 'Stripe is not configured' if key.blank?

        Stripe.api_key = key
      end
    end
  end
end
