# frozen_string_literal: true

module PartnerIntegrations
  # Maps Stripe webhook payloads to canonical PartnerIntegrations::CanonicalEvent objects.
  # Returns nil when the webhook type is not mapped (caller should no-op).
  #
  # Usage:
  #   event = PartnerIntegrations::StripeEventMapper.map(
  #     provider_event_type: 'payment_intent.succeeded',
  #     payload: stripe_payload,
  #     restaurant: restaurant,
  #   )
  class StripeEventMapper
    class << self
      def map(provider_event_type:, payload:, restaurant:)
        case provider_event_type.to_s
        when 'payment_intent.succeeded'
          map_payment_intent_succeeded(payload, restaurant)
        else
          nil
        end
      end

      private

      def map_payment_intent_succeeded(payload, restaurant)
        obj = payload.dig('data', 'object') || {}
        order_id = extract_order_id(obj)
        pi_id = obj['id'].to_s
        amount_cents = obj['amount_received'] || obj['amount']
        currency = obj['currency'].to_s.upcase.presence

        CanonicalEvent.new(
          event_type: 'order.payment.succeeded',
          restaurant_id: restaurant.id,
          occurred_at: Time.zone.now,
          idempotency_key: "stripe:payment_intent:#{pi_id}",
          payload: {
            provider: 'stripe',
            provider_payment_id: pi_id,
            order_id: order_id,
            amount_cents: amount_cents,
            currency: currency,
          }.compact,
        )
      rescue ArgumentError
        nil
      end

      def extract_order_id(obj)
        md = obj['metadata'] || {}
        md['order_id'] || md[:order_id] || md['orderId'] || md[:orderId] || obj['client_reference_id']
      rescue StandardError
        nil
      end
    end
  end
end
