class FeaturesController < ApplicationController
  # Public features listing - no authentication required for marketing pages
  skip_before_action :redirect_to_onboarding_if_needed
  skip_before_action :set_current_employee
  skip_before_action :set_permissions

  def index
    @features = Feature.order(:key)

    respond_to do |format|
      format.html # Marketing page
      format.json { render json: @features }
    end
  end

  def show
    @feature = Feature.find(params[:id])
    Rails.logger.debug { "FeaturesController#show: Found feature #{@feature.id}, format: #{request.format}" }

    respond_to do |format|
      format.html # Feature detail page
      format.json do
        Rails.logger.debug 'FeaturesController#show: Rendering JSON'
        render json: @feature
      end
    end
  end
end
