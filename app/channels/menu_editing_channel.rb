class MenuEditingChannel < ApplicationCable::Channel
  def subscribed
    menu_id = params[:menu_id]
    return reject unless menu_id
    
    stream_from "menu_#{menu_id}_editing"
    
    # Create or update edit session
    if current_user
      MenuEditSession.find_or_create_by(
        menu_id: menu_id,
        user: current_user
      ) do |session|
        session.session_id = connection.connection_identifier
        session.started_at = Time.current
        session.last_activity_at = Time.current
      end
      
      # Track presence
      PresenceService.user_online(
        current_user,
        connection.connection_identifier,
        resource_type: 'Menu',
        resource_id: menu_id
      )
    end
  end

  def unsubscribed
    # Clean up edit session
    if current_user && params[:menu_id]
      session = MenuEditSession.find_by(
        menu_id: params[:menu_id],
        user: current_user
      )
      session&.destroy
      
      # Mark user as offline
      PresenceService.user_offline(
        current_user,
        connection.connection_identifier
      )
    end
  end
  
  def receive(data)
    case data['action']
    when 'lock_field'
      handle_field_lock(data)
    when 'unlock_field'
      handle_field_unlock(data)
    when 'update_field'
      handle_field_update(data)
    end
  end
  
  private
  
  def handle_field_lock(data)
    menu = Menu.find_by(id: params[:menu_id])
    return unless menu && current_user
    
    MenuBroadcastService.broadcast_field_lock(
      menu,
      data['field'],
      current_user
    )
  end
  
  def handle_field_unlock(data)
    menu = Menu.find_by(id: params[:menu_id])
    return unless menu && current_user
    
    MenuBroadcastService.broadcast_field_unlock(
      menu,
      data['field'],
      current_user
    )
  end
  
  def handle_field_update(data)
    menu = Menu.find_by(id: params[:menu_id])
    return unless menu && current_user
    
    MenuBroadcastService.broadcast_menu_change(
      menu,
      { data['field'] => data['value'] },
      current_user
    )
  end
end
