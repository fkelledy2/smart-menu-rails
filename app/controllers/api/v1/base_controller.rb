module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization
      # Pagy v43+ uses Pagy::Method; fall back to Pagy::Backend for older installs
      include(defined?(Pagy::Method) ? Pagy::Method : Pagy::Backend)

      protect_from_forgery with: :null_session

      # Skip ApplicationController before_actions that are not needed for API
      skip_before_action :set_current_employee
      skip_before_action :set_permissions
      skip_before_action :redirect_to_onboarding_if_needed
      skip_around_action :switch_locale

      before_action :authenticate_api_user!
      before_action :force_json
      before_action :debug_api_request
      after_action :verify_authorized
      after_action :log_jwt_token_usage

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: { code: 'not_found', message: 'Resource not found' } }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { error: { code: 'invalid_record', message: e.record.errors.full_messages.join(', ') } },
               status: :unprocessable_content
      end

      rescue_from Pundit::NotAuthorizedError do
        render json: error_response('forbidden', 'You are not authorized to perform this action'), status: :forbidden
      end

      rescue_from ActionController::ParameterMissing do |e|
        render json: error_response('missing_parameter', "Required parameter missing: #{e.param}"), status: :bad_request
      end

      private

      def authenticate_api_user!
        raw_token = extract_token_from_header

        # Attempt admin-issued JWT authentication first (when flag is enabled)
        if Flipper.enabled?(:jwt_api_access) && raw_token.present?
          result = Jwt::TokenValidator.call(raw_jwt: raw_token, restaurant_id: params[:restaurant_id])
          if result.valid?
            @current_api_token      = result.token
            @current_api_restaurant = result.token.restaurant
            # Enforce that the token is scoped to the requested restaurant
            if params[:restaurant_id].present? && @current_api_restaurant&.id.to_s != params[:restaurant_id].to_s
              render json: error_response('forbidden', 'Token is not authorized for this restaurant'),
                     status: :forbidden
              return
            end
            # Set current_user to the admin who issued the token so Pundit works
            @current_user = result.token.admin_user
            return
          end
        end

        # Fall back to session-based JWT (existing behaviour)
        @current_user = JwtService.user_from_token(raw_token)
        return if @current_user

        render json: error_response('unauthorized', 'Invalid or missing authentication token'),
               status: :unauthorized
      end

      attr_reader :current_user, :current_api_token, :current_api_restaurant

      def api_jwt_request?
        @current_api_token.present?
      end

      # IMPORTANT: Must only be called from a before_action, never inline inside an
      # action body. Rails halts the filter chain on render inside a before_action,
      # but calling render in an action body causes AbstractController::DoubleRenderError.
      def enforce_scope!(required_scope)
        return unless api_jwt_request?
        return if Jwt::ScopeEnforcer.permitted?(token: @current_api_token, required_scope: required_scope)

        render json: error_response('forbidden', "Scope '#{required_scope}' is required for this endpoint"),
               status: :forbidden
      end

      def log_jwt_token_usage
        log_api_usage_for_current_request(response.status)
      end

      def log_api_usage_for_current_request(response_status)
        return unless @current_api_token

        @current_api_token.record_usage!(
          endpoint: request.path,
          http_method: request.method,
          ip_address: request.remote_ip,
          response_status: response_status,
        )
      rescue StandardError => e
        Rails.logger.error "[Api::V1::BaseController] JWT usage log failed: #{e.message}"
      end

      def user_signed_in?
        @current_user.present?
      end

      def extract_token_from_header
        auth_header = request.headers['Authorization']
        return nil unless auth_header&.start_with?('Bearer ')

        auth_header.split.last
      end

      def debug_api_request
        # Debug logging for API requests (can be enabled when needed)
      end

      def force_json
        request.format = :json if request.format.html?
      end

      # Standardized success response format
      def success_response(data = {}, message = nil)
        response = { success: true }
        response[:message] = message if message
        response[:data] = data unless data.empty?
        response
      end

      # Pagination metadata for collection responses
      def pagy_metadata_response(pagy)
        {
          count: pagy.count,
          page: pagy.page,
          items: pagy.limit,
          pages: pagy.pages,
          next: pagy.next,
          prev: pagy.respond_to?(:previous) ? pagy.previous : pagy.prev,
        }
      end

      # Standardized error response format
      def error_response(code, message, details = nil)
        response = {
          error: {
            code: code,
            message: message,
          },
        }
        response[:error][:details] = details if details
        response
      end
    end
  end
end
