module Payments
  class Orchestrator
    # Raised by adapters when a capture fails (card declined, Stripe error, etc.)
    class CaptureError < StandardError; end

    def initialize(provider: nil)
      @provider = provider&.to_sym
    end

    def create_payment_attempt!(ordr:, success_url:, cancel_url:)
      profile = PaymentProfile.find_or_create_by!(restaurant: ordr.restaurant) do |p|
        p.merchant_model = :restaurant_mor
        p.primary_provider = :stripe
      end

      provider = (@provider || profile.primary_provider).to_sym

      currency = ordr.restaurant.currency.presence || 'USD'

      amount_cents = ((ordr.gross.to_f - ordr.tip.to_f) * 100.0).round
      if amount_cents <= 0
        amount_cents = (ordr.ordritems.sum('ordritemprice * quantity').to_f * 100.0).round
      end

      charge_pattern = Payments::FundsFlowRouter.charge_pattern_for(
        provider: provider,
        merchant_model: profile.merchant_model,
        restaurant: ordr.restaurant,
      )

      payment_attempt = PaymentAttempt.create!(
        ordr: ordr,
        restaurant: ordr.restaurant,
        provider: provider,
        amount_cents: amount_cents,
        currency: currency,
        status: :requires_action,
        charge_pattern: charge_pattern,
        merchant_model: profile.merchant_model,
      )

      adapter = provider_adapter(provider)
      created = adapter.create_checkout_session!(
        payment_attempt: payment_attempt,
        ordr: ordr,
        amount_cents: amount_cents,
        currency: currency,
        success_url: success_url,
        cancel_url: cancel_url,
      )

      payment_attempt.update!(provider_payment_id: created.fetch(:checkout_session_id))

      {
        payment_attempt: payment_attempt,
        next_action: {
          redirect_url: created.fetch(:checkout_url),
        },
        provider_reference: created,
      }
    end

    # Create and immediately capture a PaymentIntent using a stored PaymentMethod reference.
    # Used by Auto Pay & Leave when auto_pay is armed and the order reaches billrequested.
    # Always routes through the adapter — never calls Stripe directly.
    def create_and_capture_payment_intent!(ordr:, payment_method_id:, amount_cents:, currency:)
      profile = PaymentProfile.find_or_create_by!(restaurant: ordr.restaurant) do |p|
        p.merchant_model = :restaurant_mor
        p.primary_provider = :stripe
      end

      provider = (@provider || profile.primary_provider).to_sym

      charge_pattern = Payments::FundsFlowRouter.charge_pattern_for(
        provider: provider,
        merchant_model: profile.merchant_model,
        restaurant: ordr.restaurant,
      )

      # Stable key (no random suffix) so Sidekiq retries deduplicate at the Stripe level.
      stable_idempotency_key = "auto_pay:#{ordr.id}"

      payment_attempt = PaymentAttempt.create!(
        ordr: ordr,
        restaurant: ordr.restaurant,
        provider: provider,
        amount_cents: amount_cents,
        currency: currency,
        status: :processing,
        charge_pattern: charge_pattern,
        merchant_model: profile.merchant_model,
        idempotency_key: stable_idempotency_key,
      )

      adapter = provider_adapter(provider)
      result = adapter.create_and_capture_intent!(
        payment_attempt: payment_attempt,
        ordr: ordr,
        payment_method_id: payment_method_id,
        amount_cents: amount_cents,
        currency: currency,
        idempotency_key: stable_idempotency_key,
      )

      Payments::Ledger.append!(
        provider: provider.to_s,
        provider_event_id: result.fetch(:payment_intent_id),
        provider_event_type: 'payment_intent.succeeded',
        occurred_at: Time.current,
        entity_type: :payment_attempt,
        entity_id: payment_attempt.id,
        event_type: :captured,
        amount_cents: amount_cents,
        currency: currency,
        raw_event_payload: { payment_intent_id: result.fetch(:payment_intent_id) },
      )

      { payment_attempt: payment_attempt }.merge(result)
    end

    private

    def provider_adapter(provider)
      case provider
      when :stripe
        Payments::Providers::StripeAdapter.new
      else
        raise ArgumentError, "Unsupported provider: #{provider}"
      end
    end
  end
end
