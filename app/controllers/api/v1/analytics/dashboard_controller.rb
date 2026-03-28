# frozen_string_literal: true

module Api
  module V1
    module Analytics
      # JWT-protected analytics dashboard endpoint.
      # Requires the 'analytics:read' scope on the bearer token.
      class DashboardController < Api::V1::BaseController
        skip_after_action :verify_authorized

        before_action :set_restaurant
        before_action -> { enforce_scope!('analytics:read') }

        def dashboard
          render json: {
            restaurant_id: @restaurant.id,
            period: {
              from: 30.days.ago.to_date,
              to: Date.current,
            },
            summary: {
              total_orders: total_orders,
              total_revenue: total_revenue,
              average_order_value: average_order_value,
            },
          }
        end

        private

        def set_restaurant
          @restaurant = Restaurant.find(params[:restaurant_id])
        rescue ActiveRecord::RecordNotFound
          render json: error_response('not_found', 'Restaurant not found'), status: :not_found
        end

        def recent_ordrs
          @recent_ordrs ||= @restaurant.ordrs
            .where(created_at: 30.days.ago..)
            .where(status: 'paid')
        end

        def total_orders
          recent_ordrs.count
        end

        def total_revenue
          recent_ordrs.sum(:total).to_f.round(2)
        end

        def average_order_value
          return 0.0 if total_orders.zero?

          (total_revenue / total_orders).round(2)
        end
      end
    end
  end
end
