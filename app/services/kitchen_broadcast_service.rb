# Service for broadcasting kitchen-related real-time updates
class KitchenBroadcastService
  class << self
    # Broadcast new order to kitchen
    def broadcast_new_order(order)
      return if order.blank?

      restaurant_id = order.restaurant_id

      payload = {
        event: 'new_order',
        order: order_payload(order),
        timestamp: Time.current.iso8601,
      }

      ActionCable.server.broadcast(
        "kitchen_#{restaurant_id}",
        payload,
      )

      # Also send push notification if enabled
      return if order.restaurant.user.blank?

      PushNotificationService.send_to_user(
        order.restaurant.user,
        'New Order',
        "Order ##{order.id} received",
        { type: 'new_order', order_id: order.id },
      )
    end

    # Broadcast order status change
    def broadcast_status_change(order, old_status, new_status)
      return if order.blank?

      restaurant_id = order.restaurant_id

      payload = {
        event: 'status_change',
        order_id: order.id,
        old_status: old_status,
        new_status: new_status,
        order: order_payload(order),
        timestamp: Time.current.iso8601,
      }

      # Broadcast to kitchen
      ActionCable.server.broadcast(
        "kitchen_#{restaurant_id}",
        payload,
      )

      # Broadcast to order channel
      ActionCable.server.broadcast(
        "ordr_#{order.id}_channel",
        payload,
      )
    end

    # Broadcast inventory alert
    def broadcast_inventory_alert(restaurant, item_name, current_level, threshold)
      return if restaurant.blank?

      payload = {
        event: 'inventory_alert',
        item_name: item_name,
        current_level: current_level,
        threshold: threshold,
        severity: current_level.zero? ? 'critical' : 'warning',
        timestamp: Time.current.iso8601,
      }

      ActionCable.server.broadcast(
        "kitchen_#{restaurant.id}",
        payload,
      )

      # Send push notification for critical alerts
      return unless current_level.zero? && restaurant.user.present?

      PushNotificationService.send_kitchen_notification(
        restaurant,
        "Out of Stock: #{item_name}",
        { type: 'inventory_critical', item: item_name },
      )
    end

    # Broadcast staff assignment
    def broadcast_staff_assignment(order, staff_user)
      return unless order.present? && staff_user.present?

      restaurant_id = order.restaurant_id

      payload = {
        event: 'staff_assignment',
        order_id: order.id,
        staff: {
          id: staff_user.id,
          email: staff_user.email,
        },
        timestamp: Time.current.iso8601,
      }

      ActionCable.server.broadcast(
        "kitchen_#{restaurant_id}",
        payload,
      )

      # Notify assigned staff
      ActionCable.server.broadcast(
        "user_#{staff_user.id}_channel",
        payload,
      )
    end

    # Broadcast kitchen metrics update
    def broadcast_kitchen_metrics(restaurant, metrics)
      return if restaurant.blank?

      payload = {
        event: 'metrics_update',
        metrics: metrics,
        timestamp: Time.current.iso8601,
      }

      ActionCable.server.broadcast(
        "kitchen_#{restaurant.id}",
        payload,
      )
    end

    # Broadcast order queue update
    def broadcast_queue_update(restaurant)
      return if restaurant.blank?

      # Get pending orders
      pending_orders = restaurant.ordrs
        .where(status: %w[opened ordered])
        .order(created_at: :asc)

      payload = {
        event: 'queue_update',
        queue_length: pending_orders.count,
        orders: pending_orders.limit(10).map { |o| order_payload(o) },
        timestamp: Time.current.iso8601,
      }

      ActionCable.server.broadcast(
        "kitchen_#{restaurant.id}",
        payload,
      )
    end

    private

    # Generate order payload for broadcasting
    def order_payload(order)
      {
        id: order.id,
        status: order.status,
        ordered_at: order.orderedAt,
        table: order.tablesetting&.name,
        items_count: order.ordritems.count,
        total: order.ordritems.sum(:ordritemprice),
        created_at: order.created_at,
      }
    end
  end
end
