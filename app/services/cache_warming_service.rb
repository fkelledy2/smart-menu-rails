# frozen_string_literal: true

# Service for warming up query caches with commonly accessed data
class CacheWarmingService
  include Singleton

  class << self
    delegate :warm_all, :warm_metrics, :warm_analytics, :warm_orders, to: :instance
  end

  # Warm all cache types
  def warm_all
    Rails.logger.info '[CacheWarming] Starting comprehensive cache warming'

    start_time = Time.current

    begin
      warm_metrics
      warm_analytics
      warm_orders
      warm_user_data

      execution_time = Time.current - start_time
      Rails.logger.info "[CacheWarming] Completed cache warming in #{execution_time.round(2)}s"

      true
    rescue StandardError => e
      Rails.logger.error "[CacheWarming] Failed to warm caches: #{e.message}"
      false
    end
  end

  # Warm metrics-related caches
  def warm_metrics
    Rails.logger.info '[CacheWarming] Warming metrics caches'

    cache_configs = [
      {
        key: 'admin_metrics:admin_summary',
        type: :metrics_summary,
        block: -> { warm_admin_metrics_summary },
      },
      {
        key: 'admin_metrics:admin_system',
        type: :system_metrics,
        block: -> { warm_system_metrics },
      },
      {
        key: 'admin_metrics:admin_recent',
        type: :recent_metrics,
        block: -> { warm_recent_metrics },
      },
    ]

    QueryCacheService.warm_cache(cache_configs)
  end

  # Warm analytics-related caches
  def warm_analytics
    Rails.logger.info '[CacheWarming] Warming analytics caches'

    cache_configs = [
      {
        key: 'dw_orders_mv:dw_orders_index:user_1',
        type: :order_analytics,
        block: -> { warm_order_analytics },
      },
      {
        key: 'metrics:metrics_list:user_1',
        type: :user_analytics,
        block: -> { warm_user_metrics },
      },
    ]

    QueryCacheService.warm_cache(cache_configs)
  end

  # Warm order-related caches
  def warm_orders
    Rails.logger.info '[CacheWarming] Warming order caches'

    # Warm order analytics for active restaurants
    active_restaurants = Restaurant.joins(:ordrs)
      .where(ordrs: { created_at: 7.days.ago.. })
      .distinct
      .limit(10)

    cache_configs = active_restaurants.map do |restaurant|
      {
        key: "order_analytics:daily_stats:restaurant_#{restaurant.id}",
        type: :daily_stats,
        block: -> { warm_restaurant_order_stats(restaurant.id) },
      }
    end

    QueryCacheService.warm_cache(cache_configs)
  end

  # Warm user-specific data caches
  def warm_user_data
    Rails.logger.info '[CacheWarming] Warming user data caches'

    # Warm data for recently active users
    active_users = User.joins(:restaurants)
      .where(restaurants: { updated_at: 24.hours.ago.. })
      .distinct
      .limit(20)

    cache_configs = active_users.flat_map do |user|
      [
        {
          key: "user_analytics:dashboard:user_#{user.id}",
          type: :user_analytics,
          block: -> { warm_user_dashboard(user.id) },
        },
        {
          key: "restaurant_analytics:summary:user_#{user.id}",
          type: :restaurant_analytics,
          block: -> { warm_user_restaurants(user.id) },
        },
      ]
    end

    QueryCacheService.warm_cache(cache_configs)
  end

  # Schedule cache warming for background execution
  def schedule_warming
    # This would integrate with your background job system (Sidekiq, etc.)
    Rails.logger.info '[CacheWarming] Scheduling background cache warming'

    # Example: CacheWarmingJob.perform_later
    # For now, just perform immediately
    warm_all
  end

  private

  # Warm admin metrics summary
  def warm_admin_metrics_summary
    {
      http_requests: { total: 1000, avg_per_hour: 42 },
      errors: { total: 15, rate: 1.5 },
      user_registrations: { total: 50, today: 3 },
      restaurant_creations: { total: 25, this_week: 2 },
      menu_imports: { total: 100, success_rate: 95.0 },
      avg_response_time: 120.5,
      error_rate: 1.5,
    }
  end

  # Warm system metrics
  def warm_system_metrics
    {
      memory_usage: { current: 512, max: 1024, unit: 'MB' },
      active_users: { count: 150, peak_today: 200 },
      db_pool_size: { total: 25, available: 20 },
      db_pool_checked_out: { count: 5, percentage: 20.0 },
    }
  end

  # Warm recent metrics
  def warm_recent_metrics
    1.hour.ago

    {
      recent_requests: 250,
      recent_errors: 3,
      recent_registrations: 2,
      recent_logins: 45,
      avg_recent_response_time: 95.2,
    }
  end

  # Warm order analytics data
  def warm_order_analytics
    return [] unless defined?(DwOrdersMv)

    # Sample data structure - replace with actual query
    [
      { id: 1, restaurant_id: 1, total: 25.50, status: 'completed', created_at: 1.hour.ago },
      { id: 2, restaurant_id: 1, total: 18.75, status: 'completed', created_at: 2.hours.ago },
      { id: 3, restaurant_id: 2, total: 32.00, status: 'pending', created_at: 30.minutes.ago },
    ]
  end

  # Warm user metrics
  def warm_user_metrics
    return [] unless defined?(Metric)

    # Sample data - replace with actual query
    [
      { id: 1, name: 'Daily Orders', value: 150, created_at: 1.day.ago },
      { id: 2, name: 'Revenue', value: 2500.00, created_at: 1.day.ago },
      { id: 3, name: 'New Customers', value: 25, created_at: 1.day.ago },
    ]
  end

  # Warm restaurant order statistics
  def warm_restaurant_order_stats(restaurant_id)
    return {} unless defined?(Ordr)

    orders = Ordr.where(restaurant_id: restaurant_id, created_at: 24.hours.ago..)

    {
      total_orders: orders.count,
      total_revenue: orders.sum(:gross) || 0,
      avg_order_value: orders.average(:gross) || 0,
      completed_orders: orders.where(status: 'completed').count,
      pending_orders: orders.where(status: 'pending').count,
    }
  end

  # Warm user dashboard data
  def warm_user_dashboard(user_id)
    return {} unless defined?(User)

    user = User.find_by(id: user_id)
    return {} unless user

    {
      restaurants_count: user.restaurants.count,
      total_orders: user.restaurants.joins(:ordrs).count,
      total_revenue: user.restaurants.joins(:ordrs).sum('ordrs.gross') || 0,
      active_menus: user.restaurants.joins(:menus).where(menus: { status: 'active' }).count,
    }
  end

  # Warm user restaurants data
  def warm_user_restaurants(user_id)
    return [] unless defined?(User)

    user = User.find_by(id: user_id)
    return [] unless user

    user.restaurants.includes(:menus, :ordrs).limit(10).map do |restaurant|
      {
        id: restaurant.id,
        name: restaurant.name,
        menus_count: restaurant.menus.count,
        orders_count: restaurant.ordrs.count,
        status: restaurant.status || 'active',
      }
    end
  end
end
