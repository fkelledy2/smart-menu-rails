class Payments::IntentsController < ApplicationController
  require 'stripe'
  protect_from_forgery except: [:create]
  after_action :verify_authorized

  def create
    open_order_id = params[:open_order_id]
    amount = params[:amount].to_i
    currency = params[:currency].to_s.downcase.presence || 'usd'

    @ordr = Ordr.find(open_order_id)
    authorize @ordr, :update?

    Stripe.api_key = Rails.application.credentials.stripe_secret_key

    intent = Stripe::PaymentIntent.create(
      amount: amount,
      currency: currency,
      automatic_payment_methods: { enabled: true },
      metadata: {
        order_id: @ordr.id,
        restaurant_id: @ordr.restaurant_id,
        smartmenu_id: @ordr.menu&.smartmenus&.first&.id
      }
    )

    render json: { client_secret: intent.client_secret }
  end
end
