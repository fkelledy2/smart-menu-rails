class KitchenChannel < ApplicationCable::Channel
  def subscribed
    restaurant_id = params[:restaurant_id]
    return reject unless restaurant_id

    stream_from "kitchen_#{restaurant_id}"

    # Track presence
    return unless current_user

    PresenceService.user_online(
      current_user,
      connection.connection_identifier,
      resource_type: 'Restaurant',
      resource_id: restaurant_id,
    )
  end

  def unsubscribed
    # Mark user as offline
    return unless current_user

    PresenceService.user_offline(
      current_user,
      connection.connection_identifier,
    )
  end

  def receive(data)
    # Handle incoming messages (e.g., status updates, assignments)
    case data['action']
    when 'update_status'
      handle_status_update(data)
    when 'assign_staff'
      handle_staff_assignment(data)
    end
  end

  private

  def handle_status_update(data)
    order = Ordr.find_by(id: data['order_id'])
    return unless order

    old_status = order.status
    order.update(status: data['new_status'])

    KitchenBroadcastService.broadcast_status_change(
      order,
      old_status,
      data['new_status'],
    )
  end

  def handle_staff_assignment(data)
    order = Ordr.find_by(id: data['order_id'])
    staff = User.find_by(id: data['staff_id'])
    return unless order && staff

    KitchenBroadcastService.broadcast_staff_assignment(order, staff)
  end
end
