module Api
  module V1
    class TestController < BaseController
      skip_before_action :authenticate_api_user!
      skip_after_action :verify_authorized

      def ping
        render json: { message: 'pong', timestamp: Time.current }
      end
    end
  end
end
