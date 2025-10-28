# L1 Cache Optimization: Enhanced Cache Warming Job
# Background job for intelligent cache warming operations
class CacheWarmingJob < ApplicationJob
  queue_as :cache_warming

  # Retry with exponential backoff for transient failures
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(warm_type: nil, warming_type: nil, user_id: nil, restaurant_id: nil, menu_id: nil, context: {})
    # Support both old and new parameter formats for backward compatibility
    actual_warming_type = warming_type || warm_type
    actual_context = context.merge(user_id: user_id, restaurant_id: restaurant_id, menu_id: menu_id).compact

    Rails.logger.info("[CacheWarmingJob] Starting cache warming: #{actual_warming_type}")

    start_time = Time.current

    case actual_warming_type
    when 'user_login', 'user_restaurants'
      warm_user_login_cache(actual_context[:user_id] || user_id)
    when 'restaurant_access', 'restaurant_full'
      warm_restaurant_cache(actual_context[:restaurant_id] || restaurant_id)
    when 'menu_view', 'menu_full'
      warm_menu_cache(actual_context[:menu_id] || menu_id)
    when 'scheduled_warming'
      warm_scheduled_cache
    when 'intelligent_warming'
      IntelligentCacheWarmingService.warm_user_context(actual_context[:user_id], tier: actual_context[:tier] || :warm)
    when 'time_based_warming'
      IntelligentCacheWarmingService.warm_time_based_cache
    when 'business_event_warming'
      IntelligentCacheWarmingService.warm_business_event_cache(actual_context[:event_type], actual_context)
    when 'dependency_warming'
      CacheDependencyService.warm_dependent_caches(actual_context[:cache_key], actual_context)
    else
      Rails.logger.warn("[CacheWarmingJob] Unknown warm_type: #{actual_warming_type}")
    end

    duration = ((Time.current - start_time) * 1000).round(2)
    Rails.logger.info("[CacheWarmingJob] Cache warming completed: #{actual_warming_type} in #{duration}ms")
  rescue StandardError => e
    Rails.logger.error("[CacheWarmingJob] Cache warming failed: #{actual_warming_type} - #{e.message}")
    raise
  end

  private

  def warm_user_login_cache(user_id)
    return unless user_id

    user = User.find_by(id: user_id)
    return unless user

    Rails.logger.debug { "[CacheWarmingJob] Warming user login cache for user #{user_id}" }

    # Use intelligent cache warming service
    IntelligentCacheWarmingService.warm_user_context(user_id, tier: :hot)

    # Pre-load user's most recent activity
    user.restaurants.limit(5).find_each do |restaurant|
      # Warm recent orders
      AdvancedCacheService.cached_restaurant_orders(restaurant.id, include_calculations: false)

      # Warm dashboard data
      AdvancedCacheService.cached_restaurant_dashboard(restaurant.id)
    end

    # Pre-load cross-restaurant user data
    AdvancedCacheService.cached_user_activity(user_id, days: 7)
    AdvancedCacheService.cached_user_all_orders(user_id)
  end

  def warm_restaurant_cache(restaurant_id)
    return unless restaurant_id

    restaurant = Restaurant.find_by(id: restaurant_id)
    return unless restaurant

    Rails.logger.debug { "[CacheWarmingJob] Warming restaurant cache for restaurant #{restaurant_id}" }

    # Use intelligent cache warming service
    IntelligentCacheWarmingService.warm_restaurant_context(restaurant_id, tier: :hot)

    # Pre-load time-sensitive data
    AdvancedCacheService.cached_restaurant_orders(restaurant_id, include_calculations: true)

    # Pre-load analytics for common time periods
    [1, 7, 30].each do |days|
      AdvancedCacheService.cached_order_analytics(restaurant_id, days.days.ago..Time.current)
    end
  end

  def warm_menu_cache(menu_id)
    return unless menu_id

    menu = Menu.find_by(id: menu_id)
    return unless menu

    Rails.logger.debug { "[CacheWarmingJob] Warming menu cache for menu #{menu_id}" }

    # Use intelligent cache warming service
    IntelligentCacheWarmingService.warm_menu_context(menu_id, tier: :hot)

    # Pre-load menu performance data
    [7, 30].each do |days|
      AdvancedCacheService.cached_menu_performance(menu_id, days: days)
    end

    # Pre-load individual menu items with analytics
    menu.menusections.includes(:menuitems).find_each do |section|
      AdvancedCacheService.cached_section_items_with_details(section.id)

      section.menuitems.limit(10).find_each do |item|
        AdvancedCacheService.cached_menuitem_with_analytics(item.id)
      end
    end
  end

  def warm_scheduled_cache
    Rails.logger.info('[CacheWarmingJob] Starting scheduled cache warming')

    # Use intelligent scheduled warming
    IntelligentCacheWarmingService.warm_scheduled_cache

    # Additional scheduled warming for high-traffic data
    warm_high_traffic_data
    warm_analytics_data
    warm_user_session_data
  end

  # Warm high-traffic data during off-peak hours
  def warm_high_traffic_data
    Rails.logger.debug('[CacheWarmingJob] Warming high-traffic data')

    # Most accessed restaurants in the last 24 hours
    active_restaurants = Restaurant.joins(:ordrs)
      .where(ordrs: { created_at: 24.hours.ago.. })
      .group('restaurants.id')
      .order('COUNT(ordrs.id) DESC')
      .limit(20)

    active_restaurants.find_each do |restaurant|
      # Warm restaurant dashboard (most frequently accessed)
      AdvancedCacheService.cached_restaurant_dashboard(restaurant.id)

      # Warm active menus
      restaurant.menus.where(status: 'active').limit(3).find_each do |menu|
        AdvancedCacheService.cached_menu_with_items(menu.id, locale: 'en', include_inactive: false)
      end
    end
  end

  # Warm analytics data for reporting
  def warm_analytics_data
    Rails.logger.debug('[CacheWarmingJob] Warming analytics data')

    # Warm analytics for restaurants with recent activity
    Restaurant.joins(:ordrs)
      .where(ordrs: { created_at: 7.days.ago.. })
      .distinct
      .limit(15)
      .find_each do |restaurant|
      # Warm common analytics queries
      [7, 30].each do |days|
        AdvancedCacheService.cached_order_analytics(restaurant.id, days.days.ago..Time.current)
        AdvancedCacheService.cached_restaurant_order_summary(restaurant.id, days: days)
      end
    end
  end

  # Warm data commonly accessed in user sessions
  def warm_user_session_data
    Rails.logger.debug('[CacheWarmingJob] Warming user session data')

    # Warm data for users who logged in recently
    recent_users = User.where(updated_at: 24.hours.ago..)
      .includes(:restaurants)
      .limit(10)

    recent_users.find_each do |user|
      # Warm user activity summary
      AdvancedCacheService.cached_user_activity(user.id, days: 7)

      # Warm user's restaurant data
      user.restaurants.limit(3).find_each do |restaurant|
        AdvancedCacheService.cached_restaurant_dashboard(restaurant.id)
      end
    end
  end

  # Legacy methods for compatibility
  def warm_user_restaurants(user_id)
    warm_user_login_cache(user_id)
  end

  def warm_restaurant_full(restaurant_id)
    return unless restaurant_id

    restaurant = Restaurant.find_by(id: restaurant_id)
    return unless restaurant

    # Warm all active menus for this restaurant
    restaurant.fetch_menus.select { |m| m.status == 'active' }.each do |menu|
      # Warm menu in multiple locales if available
      %w[en es fr de].each do |locale|
        AdvancedCacheService.cached_menu_with_items(menu.id, locale: locale)
      end

      # Warm menu performance data
      AdvancedCacheService.cached_menu_performance(menu.id, 30)
    end

    # Warm employee data
    restaurant.fetch_employees.each do |employee|
      AdvancedCacheService.cached_user_activity(employee.user_id, 30) if employee.user_id
    end

    Rails.logger.debug { "[CacheWarmingJob] Warmed full cache for restaurant #{restaurant_id}" }
  end

  # Warm menu and all its items with associations
  def warm_menu_full(menu_id)
    return unless menu_id

    menu = Menu.fetch(menu_id)
    return unless menu

    # Warm menu data in multiple locales
    %w[en es fr de].each do |locale|
      AdvancedCacheService.cached_menu_with_items(menu_id, locale: locale, include_inactive: false)
      AdvancedCacheService.cached_menu_with_items(menu_id, locale: locale, include_inactive: true)
    end

    # Warm menu performance analytics
    [7, 30, 90].each do |days|
      AdvancedCacheService.cached_menu_performance(menu_id, days)
    end

    # Warm menu sections and items
    menu.fetch_menusections.each do |section|
      section.fetch_menuitems.each do |item|
        # Warm item associations
        item.fetch_menuitemlocales
        item.fetch_menuitem_allergyn_mappings
        item.fetch_menuitem_size_mappings
        item.fetch_menuitem_ingredient_mappings if item.respond_to?(:fetch_menuitem_ingredient_mappings)
        item.fetch_menuitem_tag_mappings if item.respond_to?(:fetch_menuitem_tag_mappings)
      end
    end

    Rails.logger.debug { "[CacheWarmingJob] Warmed full cache for menu #{menu_id}" }
  end

  # Warm active orders for kitchen and management views
  def warm_active_orders(restaurant_id)
    return unless restaurant_id

    restaurant = Restaurant.fetch(restaurant_id)
    return unless restaurant

    # Get active orders (opened, confirmed, preparing)
    active_statuses = %w[opened confirmed preparing]
    active_orders = restaurant.fetch_ordrs.select { |o| active_statuses.include?(o.status) }

    # Warm each active order's data
    active_orders.each do |order|
      order.fetch_ordritems
      order.fetch_ordrparticipants
      order.fetch_ordractions

      # Warm tablesetting data
      order.fetch_tablesetting if order.respond_to?(:fetch_tablesetting)
    end

    # Warm kitchen analytics
    AdvancedCacheService.cached_order_analytics(restaurant_id, 1.day.ago..Time.current)

    Rails.logger.debug do
      "[CacheWarmingJob] Warmed active orders cache for restaurant #{restaurant_id} (#{active_orders.count} orders)"
    end
  end
end
