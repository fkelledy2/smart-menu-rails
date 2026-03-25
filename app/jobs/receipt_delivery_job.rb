class ReceiptDeliveryJob < ApplicationJob
  queue_as :mailers

  # Up to 3 retries with exponential backoff via Sidekiq retry logic.
  # We track retry_count on the model ourselves so it persists across restarts.
  sidekiq_options retry: 3, backtrace: true

  def perform(receipt_delivery_id)
    delivery = ReceiptDelivery.find_by(id: receipt_delivery_id)

    unless delivery
      Rails.logger.warn("[ReceiptDeliveryJob] ReceiptDelivery ##{receipt_delivery_id} not found — skipping")
      return
    end

    if delivery.sent?
      Rails.logger.info("[ReceiptDeliveryJob] ReceiptDelivery ##{receipt_delivery_id} already sent — skipping")
      return
    end

    case delivery.delivery_method
    when 'email'
      deliver_email(delivery)
    when 'sms'
      deliver_sms(delivery)
    else
      delivery.mark_failed!("Unknown delivery method: #{delivery.delivery_method}")
    end
  end

  private

  def deliver_email(delivery)
    ReceiptMailer.customer_receipt(receipt_delivery: delivery).deliver_now
    delivery.mark_sent!
  rescue StandardError => e
    delivery.increment_retry!
    delivery.mark_failed!(e.message)
    Rails.logger.error("[ReceiptDeliveryJob] Email delivery failed for ##{delivery.id}: #{e.message}")
    raise # re-raise so Sidekiq retry kicks in if retries remain
  end

  def deliver_sms(delivery)
    # SMS delivery is a stretch-goal — guarded behind the receipt_sms Flipper flag.
    # Full Twilio integration is post-v1.
    unless Flipper.enabled?(:receipt_sms)
      delivery.mark_failed!('SMS delivery is not enabled')
      return
    end

    raise NotImplementedError, 'SMS delivery is not yet implemented'
  rescue StandardError => e
    delivery.increment_retry!
    delivery.mark_failed!(e.message)
    raise
  end
end
