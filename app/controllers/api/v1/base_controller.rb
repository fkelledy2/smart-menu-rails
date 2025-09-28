module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization
      protect_from_forgery with: :null_session

      # before_action :authenticate_user!  # Temporarily disabled for debugging - testing if auth is causing empty responses
      before_action :force_json
      before_action :debug_api_request
      # after_action :verify_authorized  # Temporarily disabled for debugging

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: { code: "not_found", message: "Resource not found" } }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { error: { code: "invalid_record", message: e.record.errors.full_messages.join(", ") } }, status: :unprocessable_entity
      end

      rescue_from Pundit::NotAuthorizedError do
        render json: error_response("forbidden", "You are not authorized to perform this action"), status: :forbidden
      end

      rescue_from ActionController::ParameterMissing do |e|
        render json: error_response("missing_parameter", "Required parameter missing: #{e.param}"), status: :bad_request
      end

      private

      def debug_api_request
        # Debug logging removed - was for API routing investigation
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
            message: message
          }
        }
        response[:error][:details] = details if details
        response
      end
    end
  end
end
