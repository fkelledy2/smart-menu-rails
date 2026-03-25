# Preview all emails at http://localhost:3000/rails/mailers/receipt_mailer
class ReceiptMailerPreview < ActionMailer::Preview
  def customer_receipt
    ordr = Ordr.joins(:ordritems, :restaurant).where.not(gross: nil).first
    ordr ||= build_sample_ordr

    delivery = ReceiptDelivery.new(
      ordr: ordr,
      restaurant: ordr.restaurant,
      recipient_email: 'preview@example.com',
      delivery_method: 'email',
    )

    ReceiptMailer.customer_receipt(receipt_delivery: delivery)
  end

  private

  def build_sample_ordr
    restaurant = Restaurant.first || Restaurant.new(
      name: 'Sample Restaurant',
      address1: '123 Main St',
      city: 'Dublin',
      country: 'Ireland',
      currency: 'EUR',
    )

    ordr = Ordr.new(
      restaurant: restaurant,
      gross: 45.50,
      tax: 3.25,
      tip: 4.55,
      nett: 37.70,
      status: :paid,
      created_at: Time.current,
    )

    ordr
  end
end
