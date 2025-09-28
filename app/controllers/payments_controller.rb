class PaymentsController < ApplicationController
  require "stripe"
  skip_before_action :verify_authenticity_token, only: [:create_payment_link]
  
  # Pundit authorization
  after_action :verify_authorized

  def create_payment_link
    openOrderId = params[:openOrderId]
    @openOrdr = Ordr.find(openOrderId)
    authorize @openOrdr, :update? # Authorize against the order being paid
    amount = params[:amount].to_i;
    currency = params[:currency] || "usd"
    Stripe.api_key = Rails.application.credentials.stripe_secret_key
    price = Stripe::Price.create({
      unit_amount: amount,
      currency: currency,
      product_data: {
        name: params[:restaurantName],
        metadata: {
            restaurantId: params[:restaurantId],
            restaurantName: params[:restaurantName]
        }
      },
    })
    payment_link = Stripe::PaymentLink.create(
      line_items: [{ price: price.id, quantity: 1 }]
    )
    if @openOrdr
        @openOrdr.paymentlink = payment_link.url
        @openOrdr.save
    end
    render json: { payment_link: payment_link.url }
  end

end
