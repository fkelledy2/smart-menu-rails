# Service for broadcasting menu editing updates
class MenuBroadcastService
  class << self
    def broadcast_menu_change(menu, changes, user)
      ActionCable.server.broadcast(
        "menu_#{menu.id}_editing",
        {
          event: 'menu_change',
          menu_id: menu.id,
          changes: changes,
          user: { id: user.id, email: user.email },
          timestamp: Time.current.iso8601,
        },
      )
    end

    def broadcast_field_lock(menu, field, user)
      ActionCable.server.broadcast(
        "menu_#{menu.id}_editing",
        {
          event: 'field_locked',
          menu_id: menu.id,
          field: field,
          user: { id: user.id, email: user.email },
          timestamp: Time.current.iso8601,
        },
      )
    end

    def broadcast_field_unlock(menu, field, user)
      ActionCable.server.broadcast(
        "menu_#{menu.id}_editing",
        {
          event: 'field_unlocked',
          menu_id: menu.id,
          field: field,
          user: { id: user.id, email: user.email },
          timestamp: Time.current.iso8601,
        },
      )
    end
  end
end
