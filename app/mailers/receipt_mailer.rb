class ReceiptMailer < ApplicationMailer
  def customer_receipt(receipt_delivery:)
    @receipt_delivery = receipt_delivery
    @ordr = receipt_delivery.ordr
    @restaurant = receipt_delivery.restaurant
    @renderer = ReceiptTemplateRenderer.new(@ordr)

    subject_line = "Your receipt from #{@restaurant.name}"

    mail(
      to: receipt_delivery.recipient_email,
      subject: subject_line,
    )
  end
end
