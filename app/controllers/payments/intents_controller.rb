class Payments::IntentsController < ApplicationController
  require 'stripe'
  protect_from_forgery except: [:create]
  after_action :verify_authorized

  def create
    open_order_id = params[:open_order_id]
    amount = params[:amount].to_i
    currency = params[:currency].to_s.downcase.presence || 'usd'

    @ordr = Ordr.find_by(id: open_order_id)
    unless @ordr
      render json: { error: 'Order not found' }, status: :not_found
      return
    end
    authorize @ordr, :update?

    key = begin
      Rails.application.credentials.stripe_secret_key
    rescue StandardError => e
      Rails.logger.error("[Payments::IntentsController] Failed to read stripe_secret_key credential: #{e.message}")
      nil
    end

    if key.blank?
      key = begin
        Rails.application.credentials.dig(:stripe, :secret_key) ||
          Rails.application.credentials.dig(:stripe, :api_key)
      rescue StandardError => e
        Rails.logger.error("[Payments::IntentsController] Failed to read stripe credential keys: #{e.message}")
        nil
      end
    end

    key = ENV.fetch('STRIPE_SECRET_KEY', nil) if key.blank?
    Stripe.api_key = key if key.present?

    idempotency_key = "stripe_intent:#{@ordr.id}:#{amount}:#{currency}"
    payment_attempt = PaymentAttempt.find_or_create_by!(idempotency_key: idempotency_key) do |pa|
      pa.ordr            = @ordr
      pa.restaurant      = @ordr.restaurant
      pa.provider        = :stripe
      pa.amount_cents    = amount
      pa.currency        = currency
      pa.status          = :processing
      pa.charge_pattern  = :direct
      pa.merchant_model  = :restaurant_mor
    end

    # Re-use the existing Stripe intent if one was already created for this
    # PaymentAttempt. Without this guard every call (including retries from the
    # wallet button tapping twice) would create a fresh intent, orphaning the
    # previous one and overwriting provider_payment_id.
    if payment_attempt.provider_payment_id.present?
      intent = Stripe::PaymentIntent.retrieve(payment_attempt.provider_payment_id)
    else
      intent = Stripe::PaymentIntent.create(
        amount: amount,
        currency: currency,
        automatic_payment_methods: { enabled: true },
        metadata: {
          order_id: @ordr.id,
          restaurant_id: @ordr.restaurant_id,
          smartmenu_id: @ordr.menu&.smartmenus&.first&.id,
          payment_attempt_id: payment_attempt.id,
        },
      )
      payment_attempt.update_column(:provider_payment_id, intent.id)
    end

    render json: { client_secret: intent.client_secret }
  end
end
