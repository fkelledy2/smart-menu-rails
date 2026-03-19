# frozen_string_literal: true

class MenuOptimizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :authorize_restaurant

  def index
    @date_range = parse_date_range
    
    @optimization_service = MenuOptimizationService.new(@restaurant, date_range: @date_range)
    @optimization_plan = @optimization_service.generate_optimization_plan
    
    respond_to do |format|
      format.html
      format.json { render json: @optimization_plan }
    end
  end

  def menu_engineering
    @date_range = parse_date_range
    @menu_engineering = MenuEngineeringService.new(@restaurant, date_range: @date_range).analyze
    
    respond_to do |format|
      format.html
      format.json { render json: @menu_engineering }
    end
  end

  def pricing_recommendations
    @menuitem = @restaurant.menus.flat_map(&:menusections).flat_map(&:menuitems    @menuitem = @restaurant.menus.flat_map(&:menusections).flat_map(&:menuitems    @menuitem = @restaurantem).generate_recommendation
    
    respond_to do |format|
      format.json { render json: @recommendation }
    end
  end

  def bundling_opportunities
    @date_range = parse_date_range
    @bundling = BundlingOpportunityService.new(@restaurant, date_range: @date_range).analyze
    
    respond_to do |format|
      format.html
      format.json { render json: @bundling }
    end
  end

  def apply_optimizations
    optimization_plan = session[:optimization_plan] || MenuOptimizationService.new(@restaurant).generate_optimization_plan
    selected_actions = params[:selected_actions] || []
    
    @results = MenuOptimizationService.new(@restaurant).apply_optimization(optimization_plan, selected_actions)
    
    respond_to do |format|
      format.html { redirect_to restaurant_menu_optimizations_path(@restaurant), notice: 'Optimizations applied successfully' }
      format.json { render json: @results }
    end
  end

  private

  def set_restaurant
    @restaurant = current_user.restaurants.find(params[:restaurant_id])
  end

  def authorize_restaurant
    authorize @restaurant, :manage?
  end

  def parse_date_range
    if params[:start_date].present? && params[:end_date].present?
      Date.parse(params[:start_date])..Date.parse(params[:end_date])
    else
      30.days.ago..Date.current
    end
  rescue ArgumentError
    30.days.ago..Date.current
  end
end
