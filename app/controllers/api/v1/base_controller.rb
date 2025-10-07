module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization

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

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: { code: 'not_found', message: 'Resource not found' } }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { error: { code: 'invalid_record', message: e.record.errors.full_messages.join(', ') } },
               status: :unprocessable_entity
      end

      rescue_from Pundit::NotAuthorizedError do
        render json: error_response('forbidden', 'You are not authorized to perform this action'), status: :forbidden
      end

      rescue_from ActionController::ParameterMissing do |e|
        render json: error_response('missing_parameter', "Required parameter missing: #{e.param}"), status: :bad_request
      end

      private

      def authenticate_api_user!
        token = extract_token_from_header
        @current_user = JwtService.user_from_token(token)
        
        unless @current_user
          render json: error_response('unauthorized', 'Invalid or missing authentication token'), 
                 status: :unauthorized
        end
      end

      def current_user
        @current_user
      end

      def user_signed_in?
        @current_user.present?
      end

      def extract_token_from_header
        auth_header = request.headers['Authorization']
        return nil unless auth_header&.start_with?('Bearer ')
        
        auth_header.split(' ').last
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
