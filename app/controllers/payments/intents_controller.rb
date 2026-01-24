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

    key = begin
      Rails.application.credentials.stripe_secret_key
    rescue StandardError
      nil
    end

    if key.blank?
      key = begin
        Rails.application.credentials.dig(:stripe, :secret_key) ||
          Rails.application.credentials.dig(:stripe, :api_key)
      rescue StandardError
        nil
      end
    end

    key = ENV['STRIPE_SECRET_KEY'] if key.blank?
    Stripe.api_key = key if key.present?

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
