class ProfitMarginAnalyticsService
  def initialize(restaurant)
    @restaurant = restaurant
  end

  def dashboard_stats(date_range: 30.days.ago..Date.current)
    menuitems_with_costs = fetch_menuitems_with_costs
    
    {
      total_items: menuitems_with_costs.count,
      items_with_costs: menuitems_with_costs.count,
      average_margin_percentage: calculate_average_margin(menuitems_with_costs),
      total_potential_profit: calculate_total_potential_profit(menuitems_with_costs),
      above_target_count: count_by_status(menuitems_with_costs, 'above_target'),
      below_target_count: count_by_status(menuitems_with_costs, 'below_target'),
      critical_count: count_by_status(menuitems_with_costs, 'critical'),
      no_target_count: count_by_status(menuitems_with_costs, 'no_target'),
      top_performers: top_items_by_margin(menuitems_with_costs, 10),
      bottom_performers: bottom_items_by_margin(menuitems_with_costs, 10),
      category_breakdown: category_margin_breakdown(menuitems_with_costs),
      margin_trend: margin_trend_data(date_range)
    }
  end

  def order_profit_analytics(date_range: 30.days.ago..Date.current)
    orders = @restaurant.ordrs.where(created_at: date_range).includes(ordritems: :menuitem)
    
    {
      total_orders: orders.count,
      total_revenue: calculate_total_revenue(orders),
      total_profit: calculate_total_profit(orders),
      average_profit_per_order: calculate_average_profit_per_order(orders),
      profit_by_day_of_week: profit_by_day_of_week(orders),
      profit_by_hour: profit_by_hour(orders),
      most_profitable_items: most_profitable_items_by_volume(orders)
    }
  end

  private

  def fetch_menuitems_with_costs
    @restaurant.menus
      .includes(menusections: { menuitems: [:menuitem_costs, :profit_margin_target] })
      .flat_map { |menu| menu.menusections.flat_map(&:menuitems) }
      .select(&:has_cost_data?)
  end

  def calculate_average_margin(menuitems)
    return 0 if menuitems.empty?
    margins = menuitems.map(&:profit_margin_percentage).compact
    margins.empty? ? 0 : (margins.sum / margins.size).round(2)
  end

  def calculate_total_potential_profit(menuitems)
    menuitems.sum(&:profit_margin)
  end

  def count_by_status(menuitems, status)
    menuitems.count { |mi| mi.margin_status == status }
  end

  def top_items_by_margin(menuitems, limit)
    menuitems.sort_by(&:profit_margin_percentage).reverse.take(limit)
  end

  def bottom_items_by_margin(menuitems, limit)
    menuitems.sort_by(&:profit_margin_percentage).take(limit)
  end

  def category_margin_breakdown(menuitems)
    menuitems.group_by { |mi| mi.menusection.name }.map do |category, items|
      {
        category: category,
        item_count: items.count,
        average_margin: calculate_average_margin(items),
        total_profit: items.sum(&:profit_margin)
      }
    end.sort_by { |c| -c[:average_margin] }
  end

  def margin_trend_data(date_range)
    # Group cost records by week and calculate average margin
    MenuitemCost.where(menuitem_id: fetch_menuitems_with_costs.map(&:id))
      .where(effective_date: date_range)
      .where(is_active:       .where(is_active:       .where(is_acive_date.beginning_of_week }
      .map do |week, costs|
        menuitems = costs.map(&:menuitem).uniq
        {
          week: week,
          average_margin: calculate_average_margin(menuitems),
          item_count: menuitems.count
        }
      end.sort_by { |d| d[:week] }
  end

  def calculate_total_revenue(orders)
    orders.sum { |order| order.ordritems.sum { |item| item.price * item.quantity } }
  end

  def calculate_total_profit(orders)
    orders.sum do |order|
      order.ordritems.sum do |item|
        next 0 unless item.menuitem&.has_cost_data?
        (item.menuitem.profit_margin * item.quantity)
      end
    end
  end

  def calculate_average_profit_per_order(orders)
    return 0 if orders.empty?
    (calculate_total_profit(orders) / orders.count).round(2)
  end

  def profit_by_day_of_week(orders)
    orders.group_by { |o| o.created_at.strftime('%A') }.map do |day, day_orders|
      {
        day: day,
        profit: calculate_total_profit(day_orders),
        order_count: day_orders.count
      }
    end
  end

  def profit_by_hour(orders)
    orders.group_by { |o| o.created_at.hour }.map do |hour, hour_orders|
      {
        hour: hour,
        profit: calculate_total_profit(hour_orders),
        order_count: hour_orders.count
      }
    end.sort_by { |h| h[:hour] }
  end

  def most_profitable_items_by_volume(orders)
    item_profits = Hash.new { |h, k| h[k] = { quantity: 0, profit: 0 } }
    
    orders.each do |order|
      order.ordritems.each do |item|
        next unless item.menuitem&.has_cost_data?
        item_profits[item.menuitem][:quantity] += item.quantity
        item_profits[item.menuitem][:profit] += (item.menuitem.profit_margin * item.quantity)
      end
    end

    item_profits.map do |menuitem, data|
      {
        menuitem: menuitem,
        quantity_sold: data[:quantity],
        total_profit: data[:profit],
        profit_per_unit: menuitem.profit_margin
      }
    end.sort_by { |i| -i[:total_profit] }.take(20)
  end
end
