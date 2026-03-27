# frozen_string_literal: true

# Concern for API controllers that accept JWT bearer tokens.
#
# When included, adds:
#   - `before_action :authenticate_jwt_token!` — validates the token and sets
#     `current_api_restaurant` and `current_api_token`
#   - `enforce_scope!(scope)` helper — call in individual actions to assert the
#     required scope and return 403 if the token lacks it
#   - after_action `log_api_usage` — writes a JwtTokenUsageLog for every request
#
# Only active when the `jwt_api_access` Flipper flag is enabled.
module JwtAuthenticated
  extend ActiveSupport::Concern

  included do
    prepend_before_action :authenticate_jwt_token!
    after_action :log_api_usage
  end

  private

  # Authenticates the JWT bearer token in the Authorization header.
  # Sets @current_api_token and @current_api_restaurant on success.
  def authenticate_jwt_token!
    unless Flipper.enabled?(:jwt_api_access)
      render json: error_response('feature_disabled', 'JWT API access is not enabled'),
             status: :service_unavailable
      return
    end

    raw_jwt = extract_bearer_token
    unless raw_jwt
      render json: error_response('unauthorized', 'Bearer token required'),
             status: :unauthorized
      return
    end

    restaurant_id = params[:restaurant_id]
    result = Jwt::TokenValidator.call(raw_jwt: raw_jwt, restaurant_id: restaurant_id)

    unless result.valid?
      status_code = result.error.in?(%i[expired revoked invalid not_found]) ? :unauthorized : :forbidden
      message = {
        expired: 'Token has expired',
        revoked: 'Token has been revoked',
        invalid: 'Invalid authentication token',
        not_found: 'Token not recognised',
        restaurant_mismatch: 'Token is not valid for this restaurant',
      }[result.error] || 'Authentication failed'

      render json: error_response('unauthorized', message), status: status_code
      return
    end

    @current_api_token      = result.token
    @current_api_restaurant = result.token.restaurant
    @_jwt_raw               = raw_jwt
  end

  def current_api_token
    @current_api_token
  end

  def current_api_restaurant
    @current_api_restaurant
  end

  # Asserts that the current token includes the required scope.
  # Renders 403 and halts the action if not permitted.
  def enforce_scope!(required_scope)
    return if Jwt::ScopeEnforcer.permitted?(token: @current_api_token, required_scope: required_scope)

    log_api_usage(override_status: 403)
    render json: error_response('forbidden', "Scope '#{required_scope}' is required for this endpoint"),
           status: :forbidden
  end

  def log_api_usage(override_status: nil)
    return unless @current_api_token

    status_code = override_status || response.status
    @current_api_token.record_usage!(
      endpoint: request.path,
      http_method: request.method,
      ip_address: request.remote_ip,
      response_status: status_code,
    )
  rescue StandardError => e
    # Never let logging crash the request
    Rails.logger.error "[JwtAuthenticated] Usage log failed: #{e.message}"
  end

  def extract_bearer_token
    auth = request.headers['Authorization']
    return nil unless auth&.start_with?('Bearer ')

    auth.split(' ', 2).last.presence
  end
end
