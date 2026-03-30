class ProfitMarginsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant

  def index
    redirect_to edit_restaurant_path(@restaurant, section: 'profitability_margins')
  end

  def report
    redirect_to edit_restaurant_path(@restaurant, section: 'profitability_margins')
  end

  def order_analytics
    redirect_to edit_restaurant_path(@restaurant, section: 'profitability_analytics')
  end

  def inventory_alerts
    redirect_to edit_restaurant_path(@restaurant, section: 'profitability_margins')
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find_by(id: params[:restaurant_id])
    head :not_found unless @restaurant
  end
end
