module Api
  module V1
    class TestController < BaseController
      skip_before_action :authenticate_api_user!
      skip_after_action :verify_authorized

      def ping
        if Rails.env.test?
          Rails.logger.warn '[TEST DEBUG] HIT Api::V1::TestController#ping - DIRECT LOG'
          Rails.logger.debug '[TEST DEBUG] HIT Api::V1::TestController#ping - PUTS OUTPUT'
          warn '[TEST DEBUG] HIT Api::V1::TestController#ping - STDERR OUTPUT'
        end
        render json: { message: 'pong', timestamp: Time.current }
      end
    end
  end
end
