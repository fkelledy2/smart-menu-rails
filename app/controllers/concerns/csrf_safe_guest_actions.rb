# frozen_string_literal: true

# Provides origin validation for guest-accessible actions that skip CSRF.
# These actions (ordering, payments) must be accessible without a session-based
# CSRF token, but we still want to ensure the request originates from our app.
module CsrfSafeGuestActions
  extend ActiveSupport::Concern

  included do
    before_action :validate_request_origin, if: :csrf_skipped_action?
  end

  private

  def csrf_skipped_action?
    # Override in including controllers to specify which actions are CSRF-exempt
    false
  end

  def validate_request_origin
    origin = request.headers['Origin'] || request.headers['Referer']
    return if origin.blank? && request.format.html? # Same-origin form POST (no Origin header)

    return if trusted_origin?(origin)

    Rails.logger.warn("[CSRF] Blocked cross-origin request from #{origin} to #{request.path}")
    head :forbidden
  end

  def trusted_origin?(origin)
    return true if origin.blank?

    uri = URI.parse(origin.to_s)
    host = uri.host.to_s.downcase

    host == 'mellow.menu' ||
      host.end_with?('.mellow.menu') ||
      (Rails.env.local? && %w[localhost 127.0.0.1].include?(host))
  rescue URI::InvalidURIError
    false
  end
end
