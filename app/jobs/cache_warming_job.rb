# Background job for warming caches to improve user experience
class CacheWarmingJob < ApplicationJob
  queue_as :default
  
  # Retry on Redis connection issues but not on data errors
  retry_on Redis::ConnectionError, attempts: 3, wait: :exponentially_longer
  retry_on ActiveRecord::ConnectionNotEstablished, attempts: 2, wait: 5.seconds
  
  def perform(user_id: nil, restaurant_id: nil, menu_id: nil, warm_type:)
    start_time = Time.current
    
    case warm_type
    when 'user_restaurants'
      warm_user_restaurants(user_id)
    when 'restaurant_full'
      warm_restaurant_full(restaurant_id)
    when 'menu_full'
      warm_menu_full(menu_id)
    when 'active_orders'
      warm_active_orders(restaurant_id)
    else
      Rails.logger.warn("[CacheWarmingJob] Unknown warm_type: #{warm_type}")
      return
    end
    
    execution_time = Time.current - start_time
    Rails.logger.info("[CacheWarmingJob] Completed #{warm_type} warming in #{execution_time.round(3)}s")
    
  rescue => e
    Rails.logger.error("[CacheWarmingJob] Failed to warm #{warm_type}: #{e.message}")
    raise e
  end

  private

  # Warm cache for user's restaurants and dashboard data
  def warm_user_restaurants(user_id)
    return unless user_id

    user = User.fetch(user_id)
    return unless user

    # Warm user's restaurants
    restaurants = user.fetch_restaurants
    
    restaurants.each do |restaurant|
      # Warm restaurant dashboard data
      AdvancedCacheService.cached_restaurant_dashboard(restaurant.id)
      
      # Warm recent orders for each restaurant
      AdvancedCacheService.cached_order_analytics(restaurant.id, 7.days.ago..Time.current)
      
      # Warm active menus
      restaurant.fetch_menus.select { |m| m.status == 'active' }.each do |menu|
        AdvancedCacheService.cached_menu_with_items(menu.id, locale: 'en')
      end
    end

    Rails.logger.debug("[CacheWarmingJob] Warmed cache for user #{user_id} (#{restaurants.count} restaurants)")
  end

  # Warm comprehensive restaurant data
  def warm_restaurant_full(restaurant_id)
    return unless restaurant_id

    restaurant = Restaurant.fetch(restaurant_id)
    return unless restaurant

    # Warm restaurant dashboard
    AdvancedCacheService.cached_restaurant_dashboard(restaurant_id)
    
    # Warm restaurant orders (multiple time ranges)
    [7.days.ago, 30.days.ago, 90.days.ago].each do |start_date|
      AdvancedCacheService.cached_order_analytics(restaurant_id, start_date..Time.current)
    end

    # Warm all active menus for this restaurant
    restaurant.fetch_menus.select { |m| m.status == 'active' }.each do |menu|
      # Warm menu in multiple locales if available
      ['en', 'es', 'fr', 'de'].each do |locale|
        AdvancedCacheService.cached_menu_with_items(menu.id, locale: locale)
      end
      
      # Warm menu performance data
      AdvancedCacheService.cached_menu_performance(menu.id, 30)
    end

    # Warm employee data
    restaurant.fetch_employees.each do |employee|
      AdvancedCacheService.cached_user_activity(employee.user_id, 30) if employee.user_id
    end

    Rails.logger.debug("[CacheWarmingJob] Warmed full cache for restaurant #{restaurant_id}")
  end

  # Warm menu and all its items with associations
  def warm_menu_full(menu_id)
    return unless menu_id

    menu = Menu.fetch(menu_id)
    return unless menu

    # Warm menu data in multiple locales
    ['en', 'es', 'fr', 'de'].each do |locale|
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

    Rails.logger.debug("[CacheWarmingJob] Warmed full cache for menu #{menu_id}")
  end

  # Warm active orders for kitchen and management views
  def warm_active_orders(restaurant_id)
    return unless restaurant_id

    restaurant = Restaurant.fetch(restaurant_id)
    return unless restaurant

    # Get active orders (opened, confirmed, preparing)
    active_statuses = ['opened', 'confirmed', 'preparing']
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

    Rails.logger.debug("[CacheWarmingJob] Warmed active orders cache for restaurant #{restaurant_id} (#{active_orders.count} orders)")
  end
end
