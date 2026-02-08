class Payments::BaseController < ApplicationController
  require 'stripe'
  skip_before_action :verify_authenticity_token, only: [:create_payment_link]

  # Pundit authorization
  after_action :verify_authorized

  def create_payment_link
    openOrderId = params[:openOrderId]
    @openOrdr = Ordr.find(openOrderId)
    authorize @openOrdr, :update? # Authorize against the order being paid
    amount = params[:amount].to_i
    currency = params[:currency] || 'usd'
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

    key = ENV.fetch('STRIPE_SECRET_KEY', nil) if key.blank?
    Stripe.api_key = key if key.present?
    price = Stripe::Price.create({
      unit_amount: amount,
      currency: currency,
      product_data: {
        name: params[:restaurantName],
        metadata: {
          restaurantId: params[:restaurantId],
          restaurantName: params[:restaurantName],
        },
      },
    })
    payment_link = Stripe::PaymentLink.create(
      line_items: [{ price: price.id, quantity: 1 }],
    )
    if @openOrdr
      @openOrdr.paymentlink = payment_link.url
      @openOrdr.save
    end
    render json: { payment_link: payment_link.url }
  end

  def generate_qr
    # Placeholder for QR generation functionality
    # Add implementation as needed
    authorize current_user # Basic authorization for now
    render json: { message: 'QR generation endpoint ready' }
  end
end
