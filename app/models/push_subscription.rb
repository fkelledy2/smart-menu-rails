class PushSubscription < ApplicationRecord
  belongs_to :user
  
  # Validations
  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh_key, presence: true
  validates :auth_key, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_user, ->(user) { where(user: user) }
  
  # Send a push notification to this subscription
  def send_notification(title, body, data = {})
    return unless active?
    
    # Ensure data uses string keys for Sidekiq 7.0 compatibility
    string_data = data.is_a?(Hash) ? data.deep_stringify_keys : data
    
    PushNotificationJob.perform_async(
      id,
      {
        'title' => title,
        'body' => body,
        'data' => string_data,
        'icon' => '/icons/smart-menu-192.png',
        'badge' => '/icons/smart-menu-icon.png'
      }
    )
  end
  
  # Deactivate this subscription (e.g., when it becomes invalid)
  def deactivate!
    update(active: false)
  end
end
