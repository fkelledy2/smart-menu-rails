# frozen_string_literal: true

module Api
  module V2
    class BaseController < ApplicationController
      protect_from_forgery with: :null_session

      # Skip all web-specific callbacks
      skip_before_action :authenticate_user!, raise: false
      skip_before_action :set_current_employee, raise: false
      skip_before_action :set_permissions, raise: false
      skip_before_action :redirect_to_onboarding_if_needed, raise: false
      skip_around_action :switch_locale, raise: false

      before_action :force_json
      before_action :enforce_rate_limit
      after_action :set_attribution_header

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: 'Not found' }, status: :not_found
      end

      private

      def force_json
        request.format = :json if request.format.html?
      end

      def enforce_rate_limit
        key = "api_v2:#{request.remote_ip}"
        count = Rails.cache.increment(key, 1, expires_in: 1.hour, initial: 0)
        if count.to_i > rate_limit
          render json: { error: "Rate limit exceeded. Max #{rate_limit} requests/hour." },
                 status: :too_many_requests
        end
      end

      def rate_limit
        100
      end

      def set_attribution_header
        response.headers['X-Data-Attribution'] = 'Data by mellow.menu — https://www.mellow.menu'
      end

      def paginate(scope)
        page = [params[:page].to_i, 1].max
        per_page = [[params[:per_page].to_i, 1].max, 50].min
        per_page = 25 if params[:per_page].blank?

        records = scope.offset((page - 1) * per_page).limit(per_page)
        total = scope.count

        {
          data: records,
          meta: {
            page: page,
            per_page: per_page,
            total: total,
            total_pages: (total.to_f / per_page).ceil,
          },
        }
      end
    end
  end
end
