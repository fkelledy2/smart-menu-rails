class RestaurantAnalyticsMv < ApplicationRecord
  self.table_name = 'restaurant_analytics_mv'

  # Materialized views don't have a primary key by default
  self.primary_key = nil

  # Make the model read-only since it's a materialized view
  def readonly?
    true
  end

  # Scopes for common queries
  scope :for_restaurant, ->(restaurant_id) { where(restaurant_id: restaurant_id) }
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :for_month, ->(month) { where(month: month) }
  scope :recent, ->(days = 30) { where(date: days.days.ago..) }

  # Aggregation methods
  def self.total_orders_for_restaurant(restaurant_id, date_range = nil)
    query = for_restaurant(restaurant_id)
    query = query.for_date_range(date_range.begin, date_range.end) if date_range
    query.sum(:total_orders)
  end

  def self.total_revenue_for_restaurant(restaurant_id, date_range = nil)
    query = for_restaurant(restaurant_id)
    query = query.for_date_range(date_range.begin, date_range.end) if date_range
    query.sum(:total_revenue)
  end

  def self.daily_metrics(restaurant_id, date_range = nil)
    query = for_restaurant(restaurant_id)
    query = query.for_date_range(date_range.begin, date_range.end) if date_range
    query.group(:date)
      .sum(:total_orders, :completed_orders, :total_revenue)
  end

  def self.hourly_distribution(restaurant_id, date_range = nil)
    query = for_restaurant(restaurant_id)
    query = query.for_date_range(date_range.begin, date_range.end) if date_range
    result = query.group(:hour).sum(:total_orders)

    # Handle case where no records exist (sum returns 0 instead of empty hash)
    return {} if result.is_a?(Integer)

    result.sort_by { |hour, _| hour }.to_h
  end

  def self.peak_hours(restaurant_id, date_range = nil, limit = 3)
    hourly_distribution(restaurant_id, date_range)
      .sort_by { |_, orders| -orders }
      .first(limit)
      .to_h
  end
end
