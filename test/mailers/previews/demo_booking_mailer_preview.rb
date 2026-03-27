# Preview all emails at http://localhost:3000/rails/mailers/demo_booking_mailer
class DemoBookingMailerPreview < ActionMailer::Preview
  def confirmation
    booking = DemoBooking.new(
      restaurant_name: 'The Harbour Kitchen',
      contact_name: 'Jane Smith',
      email: 'jane@therestaurant.com',
      phone: '+353 1 234 5678',
      restaurant_type: 'casual_dining',
      location_count: '2-5',
      interests: 'QR ordering, auto-pay, kitchen display',
      conversion_status: 'pending',
    )

    DemoBookingMailer.confirmation(booking)
  end
end
