# frozen_string_literal: true

module Api
  module V1
    module Partner
      # GET /api/v1/restaurants/:restaurant_id/partner/crm
      # JWT-protected. Requires 'crm:read' scope.
      class CrmController < Api::V1::BaseController
        before_action :set_restaurant
        before_action -> { enforce_scope!('crm:read') }

        def crm
          authorize @restaurant, :crm?, policy_class: PartnerIntegrationPolicy

          window = params.fetch(:window_minutes, 60).to_i

          result = PartnerIntegrations::CrmExportService.new(
            restaurant: @restaurant,
            window_minutes: window,
          ).call

          render json: result
        end

        private

        def set_restaurant
          @restaurant = Restaurant.find(params[:restaurant_id])
        rescue ActiveRecord::RecordNotFound
          render json: error_response('not_found', 'Restaurant not found'), status: :not_found
        end
      end
    end
  end
end
