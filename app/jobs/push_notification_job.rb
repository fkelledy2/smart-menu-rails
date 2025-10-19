# Background job for sending push notifications
class PushNotificationJob
  include Sidekiq::Job
  
  sidekiq_options retry: 3, queue: :default
  
  def perform(subscription_id, payload)
    subscription = PushSubscription.find_by(id: subscription_id)
    return unless subscription&.active?
    
    # Check if webpush gem is available
    unless defined?(WebPush)
      Rails.logger.warn "[PushNotification] WebPush gem not available, skipping notification"
      return
    end
    
    begin
      WebPush.payload_send(
        message: payload.to_json,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh_key,
        auth: subscription.auth_key,
        vapid: vapid_config
      )
      
      Rails.logger.info "[PushNotification] Sent notification to subscription #{subscription_id}"
    rescue WebPush::InvalidSubscription => e
      # Subscription is no longer valid, deactivate it
      Rails.logger.warn "[PushNotification] Invalid subscription #{subscription_id}: #{e.message}"
      subscription.deactivate!
    rescue WebPush::ExpiredSubscription => e
      # Subscription has expired, deactivate it
      Rails.logger.warn "[PushNotification] Expired subscription #{subscription_id}: #{e.message}"
      subscription.deactivate!
    rescue StandardError => e
      # Log other errors but don't deactivate subscription
      Rails.logger.error "[PushNotification] Error sending notification to #{subscription_id}: #{e.message}"
      raise e if Rails.env.test? # Re-raise in test environment
    end
  end
  
  private
  
  def vapid_config
    {
      subject: ENV.fetch('VAPID_SUBJECT', 'mailto:notifications@smartmenu.com'),
      public_key: ENV.fetch('VAPID_PUBLIC_KEY', ''),
      private_key: ENV.fetch('VAPID_PRIVATE_KEY', '')
    }
  end
end
