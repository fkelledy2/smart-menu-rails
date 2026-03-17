class ProfitMarginsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant

  def index
    @analytics = ProfitMarginAnalyticsService.new(@restaurant)
    @stats = @analytics.dashboard_stats
    @menuitems_with_costs = @restaurant.menus
      .includes(menusections: { menuitems: %i[menuitem_costs profit_margin_target] })
      .flat_map { |menu| menu.menusections.flat_map(&:menuitems) }
      .select(&:has_cost_data?)
  end

  def report
    @analytics = ProfitMarginAnalyticsService.new(@restaurant)
    @stats = @analytics.dashboard_stats
    @menuitems = @restaurant.menus
      .includes(menusections: { menuitems: %i[menuitem_costs profit_margin_target] })
      .flat_map { |menu| menu.menusections.flat_map(&:menuitems) }
      .select(&:has_cost_data?)
  end

  def order_analytics
    date_range = params[:days]&.to_i&.days&.ago || 30.days.ago
    @analytics = ProfitMarginAnalyticsService.new(@restaurant)
    @order_stats = @analytics.order_profit_analytics(date_range: date_range..Date.current)
    @dashboard_stats = @analytics.dashboard_stats
  end

  def inventory_alerts
    analyzer = InventoryProfitAnalyzerService.new(@restaurant)
    @high_margin_low_stock = analyzer.high_margin_low_stock_items
    @out_of_stock = analyzer.out_of_stock_profitable_items
    @reorder_suggestions = analyzer.reorder_suggestions
    @total_impact = @reorder_suggestions.sum { |s| s[:estimated_profit_impact] }
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end
end
