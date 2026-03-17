class ProfitMarginsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant

  def index
    @menuitems_with_costs = @restaurant.menus
                                       .includes(menusections: { menuitems: [:menuitem_costs, :profit_margin_target] })
                                       .flat_map { |menu| menu.menusections.flat_map(&:menuitems) }
                                       .select(&:has_cost_data?)
  end

  def report
    @menuitems = @restaurant.menus
                            .includes(menusections: { menuitems: [:menuitem_costs, :profit_margin_target] })
                            .flat_map { |menu| menu.menusections.flat_map(&:menuitems) }
                            .select(&:has_cost_data?)
    
    @stats = {
      total_items: @menuitems.count,
      avg_margin: @menuitems.map(&:profit_margin_percentage).compact.sum / [@menuitems.count, 1].max,
      above_target: @menuitems.c      above_target: @menutus == 'above_target' },
      below_target: @menuitems.count { |mi| mi.margin_status == 'below_target' },
      critical: @menuitems.count { |mi| mi.margin_status == 'critical' }
    }
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end
end
