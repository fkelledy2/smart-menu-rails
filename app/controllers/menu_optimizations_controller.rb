# frozen_string_literal: true

class MenuOptimizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant

  def index
    redirect_to edit_restaurant_path(@restaurant, section: 'profitability')
  end

  def menu_engineering
    redirect_to edit_restaurant_path(@restaurant, section: 'profitability_optimization')
  end

  def bundling_opportunities
    redirect_to edit_restaurant_path(@restaurant, section: 'profitability')
  end

  def apply_optimizations
    redirect_to edit_restaurant_path(@restaurant, section: 'profitability'),
                notice: 'Optimization applied.'
  end

  private

  def set_restaurant
    @restaurant = current_user.restaurants.find(params[:restaurant_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to restaurants_path, alert: 'Restaurant not found.'
  end
end
