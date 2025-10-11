class FeaturesController < ApplicationController
  # Public features listing - no authentication required for marketing pages

  def index
    @features = Feature.order(:key)

    respond_to do |format|
      format.html # Marketing page
      format.json { render json: @features }
    end
  end

  def show
    @feature = Feature.find(params[:id])

    respond_to do |format|
      format.html # Feature detail page
      format.json { render json: @feature }
    end
  end
end
