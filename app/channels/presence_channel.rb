class PresenceChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'presence_channel'

    # Mark user as online
    if current_user
      session_id = connection.connection_identifier
      PresenceService.user_online(current_user, session_id)
    end
  end

  def unsubscribed
    # Mark user as offline
    if current_user
      session_id = connection.connection_identifier
      PresenceService.user_offline(current_user, session_id)
    end
  end

  def appear(_data)
    # User activity detected
    if current_user
      PresenceService.touch_activity(connection.connection_identifier)
    end
  end

  def away
    # User went idle
    if current_user
      PresenceService.user_idle(current_user, connection.connection_identifier)
    end
  end
end
