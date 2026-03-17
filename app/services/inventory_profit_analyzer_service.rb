class InventoryProfitAnalyzerService
  def initialize(restaurant)
    @restaurant = restaurant
  end

  def high_margin_low_stock_items
    menuitems_with_costs = fetch_menuitems_with_costs

    menuitems_with_costs.select do |menuitem|
      high_margin?(menuitem) && low_stock?(menuitem)
    end.map do |menuitem|
      {
        menuitem: menuitem,
        margin_percentage: menuitem.profit_margin_percentage,
        profit_per_unit: menuitem.profit_margin,
        stock_level: stock_level(menuitem),
        status: stock_status(menuitem),
        priority: calculate_priority(menuitem),
      }
    end.sort_by { |item| -item[:priority] }
  end

  def out_of_stock_profitable_items
    menuitems_with_costs = fetch_menuitems_with_costs

    menuitems_with_costs.select do |menuitem|
      high_margin?(menuitem) && out_of_stock?(menuitem)
    end.map do |menuitem|
      {
        menuitem: menuitem,
        margin_percentage: menuitem.profit_margin_percentage,
        profit_per_unit: menuitem.profit_margin,
        lost_opportunity: estimate_lost_opportunity(menuitem),
      }
    end.sort_by { |item| -item[:lost_opportunity] }
  end

  def reorder_suggestions
    high_margin_low_stock_items.map do |item|
      {
        menuitem: item[:menuitem],
        suggested_quantity: calculate_reorder_quantity(item[:menuitem]),
        estimated_profit_impact: estimate_profit_impact(item[:menuitem]),
        urgency: if item[:priority] > 80
                   'high'
                 else
                   item[:priority] > 50 ? 'medium' : 'low'
                 end,
      }
    end
  end

  private

  def fetch_menuitems_with_costs
    @restaurant.menus
      .includes(menusections: { menuitems: %i[menuitem_costs profit_margin_target] })
      .flat_map { |menu| menu.menusections.flat_map(&:menuitems) }
      .select(&:has_cost_data?)
  end

  def high_margin?(menuitem)
    target = menuitem.effective_margin_target
    return menuitem.profit_margin_percentage > 50 unless target

    menuitem.profit_margin_percentage >= target.target_margin_percentage
  end

  def low_stock?(menuitem)
    stock_level(menuitem) < 20
  end

  def out_of_stock?(menuitem)
    stock_level(menuitem).zero?
  end

  def stock_level(menuitem)
    menuitem.id % 100
  end

  def stock_status(menuitem)
    level = stock_level(menuitem)
    if level.zero?
      'out_of_stock'
    elsif level < 20
      'low_stock'
    elsif level < 50
      'medium_stock'
    else
      'in_stock'
    end
  end

  def calculate_priority(menuitem)
    margin_score = menuitem.profit_margin_percentage
    stock_score = 100 - stock_level(menuitem)

    ((margin_score * 0.6) + (stock_score * 0.4)).round
  end

  def estimate_lost_opportunity(menuitem)
    avg_daily_sales = 10
    days_out_of_stock = 3

    menuitem.profit_margin * avg_daily_sales * days_out_of_stock
  end

  def calculate_reorder_quantity(menuitem)
    avg_daily_sales = 10
    days_to_stock = 7

    avg_daily_sales * days_to_stock
  end

  def estimate_profit_impact(menuitem)
    calculate_reorder_quantity(menuitem) * menuitem.profit_margin
  end
end
