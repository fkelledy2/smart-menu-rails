class SystemAnalyticsMv < ApplicationRecord
  self.table_name = 'system_analytics_mv'
  
  # Materialized views don't have a primary key by default
  self.primary_key = nil
  
  # Make the model read-only since it's a materialized view
  def readonly?
    true
  end
  
  # Scopes for common queries
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :for_month, ->(month) { where(month: month) }
  scope :recent, ->(days = 30) { where('date >= ?', days.days.ago) }
  scope :current_month, -> { where(month: Date.current.beginning_of_month) }
  scope :previous_month, -> { where(month: 1.month.ago.beginning_of_month) }
  
  # System-wide metrics
  def self.total_metrics(date_range = nil)
    query = date_range ? for_date_range(date_range.begin, date_range.end) : all
    
    {
      total_restaurants: query.sum(:new_restaurants),
      total_users: query.sum(:new_users),
      total_menus: query.sum(:new_menus),
      total_menuitems: query.sum(:new_menuitems),
      total_orders: query.sum(:total_orders),
      total_revenue: query.sum(:total_revenue),
      active_restaurants: query.maximum(:active_restaurants) || 0
    }
  end
  
  def self.daily_growth(date_range = nil)
    query = date_range ? for_date_range(date_range.begin, date_range.end) : recent(30)
    query.group(:date)
         .sum(:new_restaurants, :new_users, :total_orders, :total_revenue)
  end
  
  def self.monthly_growth(months = 12)
    where('month >= ?', months.months.ago.beginning_of_month)
      .group(:month)
      .sum(:new_restaurants, :new_users, :total_orders, :total_revenue)
  end
  
  def self.growth_rate(metric, period = :month)
    case period
    when :month
      current = current_month.sum(metric)
      previous = previous_month.sum(metric)
    when :week
      current = recent(7).sum(metric)
      previous = where(date: 14.days.ago..7.days.ago).sum(metric)
    end
    
    return 0.0 if previous.zero?
    ((current - previous).to_f / previous * 100).round(2)
  end
  
  def self.active_restaurant_trend(days = 30)
    recent(days)
      .group(:date)
      .maximum(:active_restaurants)
      .sort_by { |date, _| date }
  end
  
  # Admin dashboard summary
  def self.admin_summary(date_range = 7.days.ago..Time.current)
    metrics = total_metrics(date_range)
    
    metrics.merge(
      growth_rates: {
        restaurants: growth_rate(:new_restaurants, :month),
        users: growth_rate(:new_users, :month),
        orders: growth_rate(:total_orders, :month),
        revenue: growth_rate(:total_revenue, :month)
      },
      daily_averages: {
        new_restaurants: (metrics[:total_restaurants].to_f / date_range.size).round(2),
        new_users: (metrics[:total_users].to_f / date_range.size).round(2),
        orders: (metrics[:total_orders].to_f / date_range.size).round(2),
        revenue: (metrics[:total_revenue].to_f / date_range.size).round(2)
      }
    )
  end
end
