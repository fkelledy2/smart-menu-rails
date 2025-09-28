# Current model for storing request-scoped data
# Provides access to current user, request ID, and other contextual information
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :request_id, :user_agent, :ip_address, :session_id

  # Convenience methods
  def self.user_id
    user&.id
  end

  def self.user_email
    user&.email
  end

  def self.authenticated?
    user.present?
  end

  # Set user and related attributes
  def self.set_user(user)
    self.user = user
  end

  # Set request context
  def self.set_request_context(request)
    self.request_id = request.request_id
    self.user_agent = request.user_agent
    self.ip_address = request.remote_ip
    self.session_id = request.session.id if request.session
  end

  # Clear all current attributes (useful for testing)
  def self.clear_all
    reset
  end
end
