class ReceiptDeliveryService
  class DeliveryError < StandardError; end

  def initialize(ordr:, delivery_method: 'email', recipient_email: nil, recipient_phone: nil, created_by_user: nil)
    @ordr = ordr
    @delivery_method = delivery_method
    @recipient_email = recipient_email&.strip
    @recipient_phone = recipient_phone&.strip
    @created_by_user = created_by_user
  end

  # Creates the ReceiptDelivery record and enqueues the background job.
  # Returns the ReceiptDelivery on success, raises DeliveryError on validation failure.
  def call
    validate_inputs!

    delivery = ReceiptDelivery.create!(
      ordr: @ordr,
      restaurant: @ordr.restaurant,
      delivery_method: @delivery_method,
      recipient_email: @recipient_email,
      recipient_phone: @recipient_phone,
      created_by_user: @created_by_user,
      status: 'pending',
    )

    ReceiptDeliveryJob.perform_later(delivery.id)

    delivery
  rescue ActiveRecord::RecordInvalid => e
    raise DeliveryError, e.message
  end

  private

  def validate_inputs!
    raise DeliveryError, 'Order must be in paid or closed status' unless @ordr.paid? || @ordr.closed?

    case @delivery_method
    when 'email'
      raise DeliveryError, 'Recipient email is required' if @recipient_email.blank?
      raise DeliveryError, 'Invalid email address' unless valid_email?(@recipient_email)
    when 'sms'
      raise DeliveryError, 'Recipient phone is required' if @recipient_phone.blank?
      raise DeliveryError, 'SMS delivery is not enabled' unless Flipper.enabled?(:receipt_sms)
    else
      raise DeliveryError, "Unknown delivery method: #{@delivery_method}"
    end
  end

  def valid_email?(address)
    address.match?(URI::MailTo::EMAIL_REGEXP)
  end
end
