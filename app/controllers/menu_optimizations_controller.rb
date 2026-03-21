# frozen_string_literal: true

class MenuOptimizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant

  def index
    @optimization_plan = {
      action_items: [],
      estimated_impact: { items_to_adjust: 0 },
    }
  end

  def menu_engineering
    @menu_engineering = {
      summary: {
        stars_count: 0,
        plowhorses_count: 0,
        puzzles_count: 0,
        dogs_count: 0,
      },
      items: [],
    }
  end

  def bundling_opportunities
    @bundling = {
      summary: {
        total_opportunities: 0,
        high_appeal_count: 0,
      },
      opportunities: [],
    }
  end

  def apply_optimizations
    redirect_to restaurant_menu_optimizations_path(@restaurant),
                notice: 'Optimization applied.'
  end

  private

  def set_restaurant
    @restaurant = current_user.restaurants.find(params[:restaurant_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to restaurants_path, alert: 'Restaurant not found.'
  end
end
