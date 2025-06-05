class PaymentsController < ApplicationController
  require "stripe"
  require "rqrcode"
  skip_before_action :verify_authenticity_token, only: [:create_payment_link]

  def generate_qr
      payment_url = params[:payment_url]
      qr_code = RQRCode::QRCode.new(payment_url)

      png = qr_code.as_png(size: 300)
      send_data png.to_s, type: "image/png", disposition: "inline"
  end

  def create_payment_link
    amount = params[:amount].to_i * 100 # Convert to cents
    currency = params[:currency] || "usd"
    Stripe.api_key = Rails.application.credentials.stripe_secret_key
    price = Stripe::Price.create({
      unit_amount: amount,
      currency: currency,
      product_data: { name: "Restaurant Bill" },
    })
    payment_link = Stripe::PaymentLink.create(
      line_items: [{ price: price.id, quantity: 1 }]
    )

    puts payment_link.url
    render json: { payment_link: payment_link.url }
  end

end
