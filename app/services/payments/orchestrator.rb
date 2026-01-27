module Payments
  class Orchestrator
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
        amount_cents = (ordr.ordritems.sum(:ordritemprice).to_f * 100.0).round
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
