class AnalyticsReportingService
  include Singleton
  
  class << self
    delegate_missing_to :instance
  end
  
  # Restaurant performance analytics using read replica
  def restaurant_performance_report(restaurant_id, date_range = 30.days.ago..Time.current)
    DatabaseRoutingService.with_analytics_connection do
      {
        overview: restaurant_overview(restaurant_id, date_range),
        orders: order_analytics(restaurant_id, date_range),
        menu_performance: menu_performance(restaurant_id, date_range),
        revenue: revenue_analytics(restaurant_id, date_range),
        customer_insights: customer_insights(restaurant_id, date_range)
      }
    end
  end
  
  # Order analytics for dashboard
  def order_analytics(restaurant_id, date_range = 7.days.ago..Time.current)
    DatabaseRoutingService.with_analytics_connection do
      base_query = Ordr.joins(:restaurant)
                      .where(restaurant_id: restaurant_id)
                      .where(created_at: date_range)
      
      {
        total_orders: base_query.count,
        completed_orders: base_query.where(status: 'completed').count,
        cancelled_orders: base_query.where(status: 'cancelled').count,
        average_order_value: calculate_average_order_value(base_query),
        orders_by_day: orders_by_day(base_query),
        orders_by_hour: orders_by_hour(base_query),
        popular_items: popular_menu_items(restaurant_id, date_range)
      }
    end
  end
  
  # Revenue analytics using replica
  def revenue_analytics(restaurant_id, date_range = 30.days.ago..Time.current)
    DatabaseRoutingService.with_analytics_connection do
      orders = Ordr.joins(:restaurant)
                   .where(restaurant_id: restaurant_id)
                   .where(created_at: date_range)
                   .where(status: 'completed')
      
      {
        total_revenue: calculate_total_revenue(orders),
        revenue_by_day: revenue_by_day(orders),
        revenue_by_month: revenue_by_month(orders),
        average_daily_revenue: calculate_average_daily_revenue(orders, date_range),
        revenue_growth: calculate_revenue_growth(restaurant_id, date_range)
      }
    end
  end
  
  # Menu performance analytics
  def menu_performance(restaurant_id, date_range = 30.days.ago..Time.current)
    DatabaseRoutingService.with_analytics_connection do
      {
        most_ordered_items: most_ordered_items(restaurant_id, date_range),
        least_ordered_items: least_ordered_items(restaurant_id, date_range),
        menu_item_revenue: menu_item_revenue(restaurant_id, date_range),
        category_performance: category_performance(restaurant_id, date_range)
      }
    end
  end
  
  # Customer insights using replica
  def customer_insights(restaurant_id, date_range = 30.days.ago..Time.current)
    DatabaseRoutingService.with_analytics_connection do
      {
        unique_customers: unique_customers_count(restaurant_id, date_range),
        repeat_customers: repeat_customers_count(restaurant_id, date_range),
        customer_frequency: customer_frequency_distribution(restaurant_id, date_range),
        peak_hours: peak_hours_analysis(restaurant_id, date_range)
      }
    end
  end
  
  # System-wide analytics for admin dashboard
  def system_analytics(date_range = 7.days.ago..Time.current)
    DatabaseRoutingService.with_analytics_connection do
      {
        total_restaurants: Restaurant.where(created_at: date_range).count,
        total_orders: Ordr.where(created_at: date_range).count,
        total_revenue: system_revenue(date_range),
        active_restaurants: active_restaurants_count(date_range),
        user_signups: User.where(created_at: date_range).count,
        menu_items_created: Menuitem.where(created_at: date_range).count
      }
    end
  end
  
  # Export data for external analysis
  def export_restaurant_data(restaurant_id, format: :csv, date_range: 30.days.ago..Time.current)
    DatabaseRoutingService.with_analytics_connection do
      case format
      when :csv
        export_to_csv(restaurant_id, date_range)
      when :json
        export_to_json(restaurant_id, date_range)
      else
        raise ArgumentError, "Unsupported format: #{format}"
      end
    end
  end
  
  private
  
  def restaurant_overview(restaurant_id, date_range)
    restaurant = Restaurant.find(restaurant_id)
    {
      name: restaurant.name,
      created_at: restaurant.created_at,
      total_menus: restaurant.menus.count,
      total_menu_items: restaurant.menus.joins(:menuitems).count,
      date_range: {
        start: date_range.begin,
        end: date_range.end
      }
    }
  end
  
  def calculate_average_order_value(orders_query)
    # This would need to be implemented based on your order total calculation
    # For now, return a placeholder
    orders_query.joins(:ordritems)
                .group('ordrs.id')
                .sum('ordritems.quantity * ordritems.unit_price')
                .values
                .sum.to_f / orders_query.count
  rescue ZeroDivisionError
    0.0
  end
  
  def orders_by_day(orders_query)
    orders_query.group_by_day(:created_at, time_zone: Time.zone).count
  end
  
  def orders_by_hour(orders_query)
    orders_query.group_by_hour_of_day(:created_at, time_zone: Time.zone).count
  end
  
  def popular_menu_items(restaurant_id, date_range)
    Ordritem.joins(ordr: :restaurant)
            .joins(:menuitem)
            .where(ordrs: { restaurant_id: restaurant_id, created_at: date_range })
            .group('menuitems.name')
            .sum(:quantity)
            .sort_by { |_, quantity| -quantity }
            .first(10)
            .to_h
  end
  
  def calculate_total_revenue(orders_query)
    orders_query.joins(:ordritems)
                .sum('ordritems.quantity * ordritems.unit_price')
  end
  
  def revenue_by_day(orders_query)
    orders_query.joins(:ordritems)
                .group_by_day('ordrs.created_at', time_zone: Time.zone)
                .sum('ordritems.quantity * ordritems.unit_price')
  end
  
  def revenue_by_month(orders_query)
    orders_query.joins(:ordritems)
                .group_by_month('ordrs.created_at', time_zone: Time.zone)
                .sum('ordritems.quantity * ordritems.unit_price')
  end
  
  def calculate_average_daily_revenue(orders_query, date_range)
    total_revenue = calculate_total_revenue(orders_query)
    days_count = (date_range.end.to_date - date_range.begin.to_date).to_i + 1
    total_revenue / days_count
  rescue ZeroDivisionError
    0.0
  end
  
  def calculate_revenue_growth(restaurant_id, date_range)
    current_period_revenue = revenue_analytics(restaurant_id, date_range)[:total_revenue]
    
    # Calculate previous period revenue for comparison
    period_length = date_range.end - date_range.begin
    previous_range = (date_range.begin - period_length)..(date_range.begin)
    previous_period_revenue = calculate_total_revenue(
      Ordr.where(restaurant_id: restaurant_id, created_at: previous_range, status: 'completed')
    )
    
    return 0.0 if previous_period_revenue.zero?
    
    ((current_period_revenue - previous_period_revenue) / previous_period_revenue * 100).round(2)
  end
  
  def most_ordered_items(restaurant_id, date_range)
    popular_menu_items(restaurant_id, date_range).first(5)
  end
  
  def least_ordered_items(restaurant_id, date_range)
    popular_menu_items(restaurant_id, date_range).last(5)
  end
  
  def menu_item_revenue(restaurant_id, date_range)
    Ordritem.joins(ordr: :restaurant)
            .joins(:menuitem)
            .where(ordrs: { restaurant_id: restaurant_id, created_at: date_range, status: 'completed' })
            .group('menuitems.name')
            .sum('ordritems.quantity * ordritems.unit_price')
            .sort_by { |_, revenue| -revenue }
            .first(10)
            .to_h
  end
  
  def category_performance(restaurant_id, date_range)
    Ordritem.joins(ordr: :restaurant)
            .joins(menuitem: :menusection)
            .where(ordrs: { restaurant_id: restaurant_id, created_at: date_range, status: 'completed' })
            .group('menusections.name')
            .sum('ordritems.quantity * ordritems.unit_price')
            .sort_by { |_, revenue| -revenue }
            .to_h
  end
  
  def unique_customers_count(restaurant_id, date_range)
    # This assumes you have customer tracking via sessions or user accounts
    Ordr.where(restaurant_id: restaurant_id, created_at: date_range)
        .distinct
        .count(:session_id) # or :user_id if you track users
  end
  
  def repeat_customers_count(restaurant_id, date_range)
    # Count customers who made more than one order
    Ordr.where(restaurant_id: restaurant_id, created_at: date_range)
        .group(:session_id) # or :user_id
        .having('COUNT(*) > 1')
        .count
        .size
  end
  
  def customer_frequency_distribution(restaurant_id, date_range)
    frequency_data = Ordr.where(restaurant_id: restaurant_id, created_at: date_range)
                         .group(:session_id)
                         .count
    
    frequency_distribution = frequency_data.values.group_by(&:itself).transform_values(&:count)
    
    {
      '1_order' => frequency_distribution[1] || 0,
      '2_orders' => frequency_distribution[2] || 0,
      '3_orders' => frequency_distribution[3] || 0,
      '4_plus_orders' => frequency_distribution.select { |k, _| k >= 4 }.values.sum
    }
  end
  
  def peak_hours_analysis(restaurant_id, date_range)
    Ordr.where(restaurant_id: restaurant_id, created_at: date_range)
        .group_by_hour_of_day(:created_at, time_zone: Time.zone)
        .count
        .sort_by { |_, count| -count }
        .first(3)
        .to_h
  end
  
  def system_revenue(date_range)
    Ordr.joins(:ordritems)
        .where(created_at: date_range, status: 'completed')
        .sum('ordritems.quantity * ordritems.unit_price')
  end
  
  def active_restaurants_count(date_range)
    Restaurant.joins(:ordrs)
              .where(ordrs: { created_at: date_range })
              .distinct
              .count
  end
  
  def export_to_csv(restaurant_id, date_range)
    require 'csv'
    
    orders = Ordr.includes(:ordritems, :restaurant)
                 .where(restaurant_id: restaurant_id, created_at: date_range)
    
    CSV.generate(headers: true) do |csv|
      csv << ['Order ID', 'Date', 'Status', 'Total Items', 'Total Value', 'Customer Session']
      
      orders.each do |order|
        total_value = order.ordritems.sum { |item| item.quantity * item.unit_price }
        csv << [
          order.id,
          order.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          order.status,
          order.ordritems.sum(:quantity),
          total_value,
          order.session_id
        ]
      end
    end
  end
  
  def export_to_json(restaurant_id, date_range)
    report_data = restaurant_performance_report(restaurant_id, date_range)
    report_data.to_json
  end
end
