# Service for managing push notifications
class PushNotificationService
  class << self
    # Send a push notification to a specific user
    def send_to_user(user, title, body, data = {})
      return unless user.present?
      
      # Convert data to string keys for Sidekiq 7.0 compatibility
      string_data = data.deep_stringify_keys
      
      subscriptions = PushSubscription.active.for_user(user)
      subscriptions.each do |subscription|
        subscription.send_notification(title, body, string_data)
      end
      
      subscriptions.count
    end
    
    # Send a push notification to multiple users
    def send_to_users(users, title, body, data = {})
      count = 0
      users.each do |user|
        count += send_to_user(user, title, body, data)
      end
      count
    end
    
    # Send order update notification
    def send_order_update(order, message)
      # Orders belong to restaurants, not users directly
      # Send notification to the restaurant owner
      return unless order.restaurant&.user.present?
      
      send_to_user(
        order.restaurant.user,
        "Order Update",
        message,
        {
          type: 'order_update',
          order_id: order.id,
          url: "/orders/#{order.id}"
        }
      )
    end
    
    # Send menu update notification
    def send_menu_update(menu, message)
      return unless menu.restaurant.user.present?
      
      send_to_user(
        menu.restaurant.user,
        "Menu Update",
        message,
        {
          type: 'menu_update',
          menu_id: menu.id,
          url: "/menus/#{menu.id}"
        }
      )
    end
    
    # Send kitchen notification
    def send_kitchen_notification(restaurant, message, data = {})
      return unless restaurant.user.present?
      
      send_to_user(
        restaurant.user,
        "Kitchen Alert",
        message,
        data.merge(type: 'kitchen_alert')
      )
    end
    
    # Test notification (for debugging)
    def send_test_notification(user)
      send_to_user(
        user,
        "Test Notification",
        "This is a test notification from Smart Menu",
        { type: 'test' }
      )
    end
  end
end
