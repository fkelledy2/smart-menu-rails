require 'stripe'

module Payments
  module Providers
    class StripeAdapter < BaseAdapter
      def create_checkout_session!(payment_attempt:, ordr:, amount_cents:, currency:, success_url:, cancel_url:)
        ensure_api_key!

        metadata = {
          order_id: ordr.id,
          restaurant_id: ordr.restaurant_id,
          payment_attempt_id: payment_attempt.id,
        }

        session = Stripe::Checkout::Session.create(
          mode: 'payment',
          success_url: success_url,
          cancel_url: cancel_url,
          client_reference_id: ordr.id.to_s,
          line_items: [
            {
              quantity: 1,
              price_data: {
                currency: currency.to_s.downcase,
                unit_amount: amount_cents,
                product_data: {
                  name: "#{ordr.restaurant.name} Order #{ordr.id}",
                },
              },
            },
          ],
          metadata: metadata,
          payment_intent_data: {
            metadata: metadata,
          },
        )

        {
          checkout_session_id: session.id.to_s,
          checkout_url: session.url.to_s,
          payment_intent_id: session.payment_intent.to_s.presence,
        }
      end

      def create_full_refund!(payment_attempt:)
        ensure_api_key!

        checkout_session_id = payment_attempt.provider_payment_id.to_s
        raise ArgumentError, 'provider_payment_id is required to refund' if checkout_session_id.blank?

        session = Stripe::Checkout::Session.retrieve(checkout_session_id, { expand: ['payment_intent'] })
        pi = session.payment_intent
        payment_intent_id = pi.respond_to?(:id) ? pi.id.to_s : pi.to_s
        raise 'Stripe Checkout Session missing payment_intent' if payment_intent_id.blank?

        refund = Stripe::Refund.create(payment_intent: payment_intent_id)

        raw = begin
          refund.to_hash
        rescue StandardError
          {}
        end

        { refund_id: refund.id.to_s, raw: raw }
      end

      private

      def ensure_api_key!
        return if Stripe.api_key.present?

        env_key = ENV['STRIPE_SECRET_KEY'].presence

        credentials_key = begin
          Rails.application.credentials.stripe_secret_key
        rescue StandardError
          nil
        end

        if credentials_key.blank?
          credentials_key = begin
            Rails.application.credentials.dig(:stripe, :secret_key) ||
              Rails.application.credentials.dig(:stripe, :api_key)
          rescue StandardError
            nil
          end
        end

        key = if Rails.env.production?
                env_key || credentials_key
              else
                credentials_key.presence || env_key
              end

        key_source = if key.blank?
                       'none'
                     elsif key == env_key
                       'env'
                     else
                       'credentials'
                     end

        raise 'Stripe is not configured' if key.blank?

        Rails.logger.warn("[Stripe] api_key_source=#{key_source}")
        Stripe.api_key = key
      end
    end
  end
end
