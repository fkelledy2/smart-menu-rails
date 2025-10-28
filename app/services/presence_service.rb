# Service for managing user presence and session tracking
class PresenceService
  class << self
    # Mark user as online and create/update session
    def user_online(user, session_id, resource_type: nil, resource_id: nil)
      return unless user.present? && session_id.present?

      session = UserSession.find_or_initialize_by(session_id: session_id)
      session.assign_attributes(
        user: user,
        resource_type: resource_type,
        resource_id: resource_id,
        status: 'active',
        last_activity_at: Time.current,
      )

      if session.save
        broadcast_presence_change(user, session, 'online')
        session
      end
    end

    # Mark user as offline
    def user_offline(user, session_id)
      return unless user.present? && session_id.present?

      session = UserSession.find_by(session_id: session_id)
      return unless session

      session.mark_offline!
      broadcast_presence_change(user, session, 'offline')

      # Clean up old sessions
      cleanup_stale_sessions(user)

      session
    end

    # Mark user as idle
    def user_idle(user, session_id)
      return unless user.present? && session_id.present?

      session = UserSession.find_by(session_id: session_id)
      return unless session

      session.mark_idle!
      broadcast_presence_change(user, session, 'idle')

      session
    end

    # Update user activity
    def touch_activity(session_id)
      session = UserSession.find_by(session_id: session_id)
      return unless session

      session.touch_activity!
      session
    end

    # Get active users for a resource
    def get_active_users(resource_type, resource_id)
      UserSession.active
        .for_resource(resource_type, resource_id)
        .recent
        .includes(:user)
        .map(&:user)
        .uniq
    end

    # Get all active sessions for a user
    def get_user_sessions(user)
      UserSession.where(user: user).active.recent
    end

    # Check if user is online
    def user_online?(user)
      UserSession.where(user: user).active.recent.exists?
    end

    # Get presence status for user
    def get_presence_status(user)
      sessions = UserSession.where(user: user).recent.order(last_activity_at: :desc)
      return 'offline' if sessions.empty?

      sessions.first.status
    end

    # Cleanup stale sessions (older than 5 minutes)
    def cleanup_stale_sessions(user = nil)
      scope = user ? UserSession.where(user: user) : UserSession
      stale_sessions = scope.stale

      stale_sessions.each do |session|
        session.mark_offline!
        broadcast_presence_change(session.user, session, 'offline')
      end

      stale_sessions.count
    end

    # Get presence summary for a resource
    def get_presence_summary(resource_type, resource_id)
      sessions = UserSession.for_resource(resource_type, resource_id).recent

      {
        total: sessions.count,
        active: sessions.active.count,
        idle: sessions.idle.count,
        users: sessions.includes(:user).map do |s|
          {
            id: s.user.id,
            email: s.user.email,
            status: s.status,
            last_activity: s.last_activity_at,
          }
        end,
      }
    end

    private

    # Broadcast presence change to relevant channels
    def broadcast_presence_change(user, session, event)
      payload = {
        user_id: user.id,
        email: user.email,
        session_id: session.session_id,
        status: session.status,
        event: event,
        timestamp: Time.current.iso8601,
      }

      # Broadcast to user's personal channel
      ActionCable.server.broadcast(
        "user_#{user.id}_presence",
        payload,
      )

      # Broadcast to resource channel if applicable
      if session.resource_type && session.resource_id
        ActionCable.server.broadcast(
          "#{session.resource_type.downcase}_#{session.resource_id}_presence",
          payload,
        )
      end

      # Broadcast to global presence channel
      ActionCable.server.broadcast(
        'presence_channel',
        payload,
      )
    end
  end
end
