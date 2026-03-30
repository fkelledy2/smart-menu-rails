class PlansController < ApplicationController
  # Public plans listing - no authentication required for marketing/pricing pages

  def index
    @plans = Plan.display_order

    respond_to do |format|
      format.html # Pricing page
      format.json { render json: @plans }
    end
  end

  def show
    @plan = Plan.find_by(id: params[:id])
    return head :not_found unless @plan

    respond_to do |format|
      format.html # Plan detail page
      format.json { render json: @plan }
    end
  end
end
