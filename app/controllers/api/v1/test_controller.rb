module Api
  module V1
    class TestController < ApplicationController
      def ping
        if Rails.env.test?
          Rails.logger.warn "[TEST DEBUG] HIT Api::V1::TestController#ping - DIRECT LOG"
          puts "[TEST DEBUG] HIT Api::V1::TestController#ping - PUTS OUTPUT"
          STDERR.puts "[TEST DEBUG] HIT Api::V1::TestController#ping - STDERR OUTPUT"
        end
        render json: { message: "pong", timestamp: Time.current }
      end
    end
  end
end
