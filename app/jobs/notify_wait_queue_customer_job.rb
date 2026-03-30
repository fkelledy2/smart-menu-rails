# frozen_string_literal: true

# Stretch-goal job: sends an SMS notification to a waiting customer when their
# table is ready. Gated behind the `wait_time_sms` Flipper flag.
#
# In v1, the body simply logs the intent. Twilio integration is wired up
# when the `wait_time_sms` Flipper flag is enabled and TWILIO_ACCOUNT_SID
# / TWILIO_AUTH_TOKEN / TWILIO_FROM_NUMBER are set in credentials.
class NotifyWaitQueueCustomerJob < ApplicationJob
  queue_as :default

  sidekiq_options retry: 3, backtrace: true

  def perform(wait_queue_id)
    entry = CustomerWaitQueue.find_by(id: wait_queue_id)
    return unless entry

    unless Flipper.enabled?(:wait_time_sms, entry.restaurant)
      Rails.logger.info(
        "[NotifyWaitQueueCustomerJob] wait_time_sms disabled for restaurant_id=#{entry.restaurant_id}, skipping",
      )
      return
    end

    if entry.customer_phone.blank?
      Rails.logger.info(
        "[NotifyWaitQueueCustomerJob] no phone for CustomerWaitQueue##{entry.id}, skipping",
      )
      return
    end

    send_sms(entry)
  end

  private

  def send_sms(entry)
    account_sid = Rails.application.credentials.dig(:twilio, :account_sid)
    auth_token  = Rails.application.credentials.dig(:twilio, :auth_token)
    from_number = Rails.application.credentials.dig(:twilio, :from_number)

    unless account_sid && auth_token && from_number
      Rails.logger.warn('[NotifyWaitQueueCustomerJob] Twilio credentials not configured')
      return
    end

    message = "Hi #{entry.customer_name}, your table for #{entry.party_size} is ready! Please come to the host stand. — #{entry.restaurant.name}"

    require 'twilio-ruby'
    client = Twilio::REST::Client.new(account_sid, auth_token)
    client.messages.create(
      from: from_number,
      to: entry.customer_phone,
      body: message,
    )

    Rails.logger.info(
      "[NotifyWaitQueueCustomerJob] SMS sent to #{entry.customer_phone} for CustomerWaitQueue##{entry.id}",
    )
  rescue StandardError => e
    Rails.logger.error(
      "[NotifyWaitQueueCustomerJob] SMS failed for CustomerWaitQueue##{entry.id}: #{e.class}: #{e.message}",
    )
    raise # Re-raise so Sidekiq can retry
  end
end
