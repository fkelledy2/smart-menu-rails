# frozen_string_literal: true

# L1 Cache Optimization: Intelligent Cache Warming Service
# Predictively warms cache based on user patterns, time patterns, and business context
class IntelligentCacheWarmingService
  include ActionView::Helpers::DateHelper

  # Cache tiers with different expiration times and priorities
  CACHE_TIERS = {
    hot: { expires_in: 5.minutes, priority: :high },
    warm: { expires_in: 30.minutes, priority: :medium },
    cold: { expires_in: 6.hours, priority: :low },
    archive: { expires_in: 24.hours, priority: :archive },
  }.freeze

  class << self
    # Warm cache based on user login patterns
    def warm_user_context(user_id, tier: :warm)
      return unless user_id

      user = User.find_by(id: user_id)
      return unless user

      Rails.logger.info("[IntelligentCacheWarmingService] Warming cache for user #{user_id}")

      CACHE_TIERS[tier]

      # Pre-load user's restaurants with dashboard data
      user.restaurants.find_each do |restaurant|
        warm_restaurant_context(restaurant.id, tier: :hot)

        # Pre-load recent orders
        AdvancedCacheService.cached_restaurant_orders(restaurant.id, include_calculations: true)

        # Pre-load employee data
        AdvancedCacheService.cached_restaurant_employees(restaurant.id, include_analytics: true)
      end

      # Pre-load user activity summary
      AdvancedCacheService.cached_user_activity(user_id, days: 7)
      AdvancedCacheService.cached_user_all_orders(user_id)
      AdvancedCacheService.cached_user_all_employees(user_id)

      Rails.logger.debug { "[IntelligentCacheWarmingService] User context warming completed for user #{user_id}" }
    end

    # Warm cache based on restaurant access patterns
    def warm_restaurant_context(restaurant_id, tier: :warm)
      return unless restaurant_id

      restaurant = Restaurant.find_by(id: restaurant_id)
      return unless restaurant

      Rails.logger.info("[IntelligentCacheWarmingService] Warming cache for restaurant #{restaurant_id}")

      CACHE_TIERS[tier]

      # Pre-load restaurant dashboard (most frequently accessed)
      AdvancedCacheService.cached_restaurant_dashboard(restaurant_id)

      # Pre-load active menus with items
      restaurant.menus.where(status: 'active').find_each do |menu|
        warm_menu_context(menu.id, tier: :hot)
      end

      # Pre-load order analytics for different time periods
      [7, 30, 90].each do |days|
        AdvancedCacheService.cached_order_analytics(restaurant_id, days.days.ago..Time.current)
        AdvancedCacheService.cached_restaurant_order_summary(restaurant_id, days: days)
      end

      # Pre-load employee summary
      AdvancedCacheService.cached_restaurant_employee_summary(restaurant_id, days: 30)

      Rails.logger.debug do
        "[IntelligentCacheWarmingService] Restaurant context warming completed for restaurant #{restaurant_id}"
      end
    end

    # Warm cache based on menu access patterns
    def warm_menu_context(menu_id, tier: :warm)
      return unless menu_id

      menu = Menu.find_by(id: menu_id)
      return unless menu

      Rails.logger.info("[IntelligentCacheWarmingService] Warming cache for menu #{menu_id}")

      CACHE_TIERS[tier]

      # Pre-load menu with items and localization
      locales = menu.restaurant.restaurantlocales.pluck(:locale).presence || ['en']
      locales.each do |locale|
        AdvancedCacheService.cached_menu_with_items(menu_id, locale: locale, include_inactive: false)
        AdvancedCacheService.cached_menu_with_items(menu_id, locale: locale, include_inactive: true)
      end

      # Pre-load menu items with details
      AdvancedCacheService.cached_menu_items_with_details(menu_id, include_analytics: true)

      # Pre-load menu performance analytics
      [7, 30, 90].each do |days|
        AdvancedCacheService.cached_menu_performance(menu_id, days: days)
      end

      # Pre-load individual sections
      menu.menusections.find_each do |section|
        AdvancedCacheService.cached_section_items_with_details(section.id)
      end

      # Warm cache keys using CacheKeyService
      CacheKeyService.warm_menu_cache(menu)

      Rails.logger.debug { "[IntelligentCacheWarmingService] Menu context warming completed for menu #{menu_id}" }
    end

    # Warm cache based on time patterns (business hours optimization)
    def warm_time_based_cache
      current_hour = Time.current.hour

      Rails.logger.info("[IntelligentCacheWarmingService] Time-based cache warming for hour #{current_hour}")

      case current_hour
      when 6..10 # Morning: Dashboard and planning data
        warm_morning_cache
      when 11..14 # Lunch: Menu and order data
        warm_lunch_cache
      when 17..21 # Dinner: Menu and real-time data
        warm_dinner_cache
      when 22..23, 0..5 # Night: Analytics and reporting data
        warm_night_cache
      end
    end

    # Warm cache for specific business events
    def warm_business_event_cache(event_type, context = {})
      Rails.logger.info("[IntelligentCacheWarmingService] Business event cache warming: #{event_type}")

      case event_type
      when 'menu_updated'
        warm_menu_update_cache(context[:menu_id])
      when 'order_placed'
        warm_order_cache(context[:restaurant_id])
      when 'employee_login'
        warm_employee_cache(context[:restaurant_id], context[:employee_id])
      when 'peak_hours_approaching'
        warm_peak_hours_cache(context[:restaurant_id])
      end
    end

    # Scheduled cache warming for off-peak hours
    def warm_scheduled_cache
      Rails.logger.info('[IntelligentCacheWarmingService] Scheduled cache warming started')

      # Warm most accessed restaurants (top 20% by activity)
      active_restaurants = Restaurant.joins(:ordrs)
        .where(ordrs: { created_at: 7.days.ago.. })
        .group('restaurants.id')
        .order('COUNT(ordrs.id) DESC')
        .limit(20)

      active_restaurants.find_each do |restaurant|
        warm_restaurant_context(restaurant.id, tier: :cold)
      end

      # Warm frequently accessed menus
      active_menus = Menu.joins(restaurant: :ordrs)
        .where(ordrs: { created_at: 7.days.ago.. })
        .where(status: 'active')
        .group('menus.id')
        .order('COUNT(ordrs.id) DESC')
        .limit(50)

      active_menus.find_each do |menu|
        warm_menu_context(menu.id, tier: :cold)
      end

      Rails.logger.info('[IntelligentCacheWarmingService] Scheduled cache warming completed')
    end

    # Get cache warming recommendations based on usage patterns
    def cache_warming_recommendations
      {
        high_priority: identify_high_priority_warming,
        time_based: identify_time_based_warming,
        business_events: identify_business_event_warming,
        memory_optimization: identify_memory_optimization_opportunities,
      }
    end

    private

    # Morning cache warming (6-10 AM)
    def warm_morning_cache
      Rails.logger.debug('[IntelligentCacheWarmingService] Morning cache warming')

      # Dashboard data for restaurant owners
      Restaurant.joins(:users).distinct.find_each do |restaurant|
        AdvancedCacheService.cached_restaurant_dashboard(restaurant.id)
        AdvancedCacheService.cached_restaurant_order_summary(restaurant.id, days: 1)
      end
    end

    # Lunch cache warming (11 AM - 2 PM)
    def warm_lunch_cache
      Rails.logger.debug('[IntelligentCacheWarmingService] Lunch cache warming')

      # Menu data for active restaurants
      Menu.joins(:restaurant).where(status: 'active').find_each do |menu|
        warm_menu_context(menu.id, tier: :hot)
      end
    end

    # Dinner cache warming (5-9 PM)
    def warm_dinner_cache
      Rails.logger.debug('[IntelligentCacheWarmingService] Dinner cache warming')

      # Same as lunch but with higher priority
      Menu.joins(:restaurant).where(status: 'active').find_each do |menu|
        warm_menu_context(menu.id, tier: :hot)
      end

      # Real-time order data
      Restaurant.find_each do |restaurant|
        AdvancedCacheService.cached_restaurant_orders(restaurant.id, include_calculations: true)
      end
    end

    # Night cache warming (10 PM - 5 AM)
    def warm_night_cache
      Rails.logger.debug('[IntelligentCacheWarmingService] Night cache warming')

      # Analytics and reporting data
      Restaurant.find_each do |restaurant|
        [7, 30].each do |days|
          AdvancedCacheService.cached_order_analytics(restaurant.id, days.days.ago..Time.current)
        end
      end
    end

    # Warm cache after menu updates
    def warm_menu_update_cache(menu_id)
      return unless menu_id

      # Invalidate old cache first
      CacheKeyService.invalidate_menu_cache(menu_id)

      # Warm new cache
      warm_menu_context(menu_id, tier: :hot)
    end

    # Warm cache after order placement
    def warm_order_cache(restaurant_id)
      return unless restaurant_id

      # Update restaurant dashboard
      AdvancedCacheService.cached_restaurant_dashboard(restaurant_id)
      AdvancedCacheService.cached_restaurant_orders(restaurant_id, include_calculations: true)
    end

    # Warm cache for employee login
    def warm_employee_cache(restaurant_id, employee_id)
      return unless restaurant_id && employee_id

      warm_restaurant_context(restaurant_id, tier: :hot)
      AdvancedCacheService.cached_employee_with_details(employee_id)
    end

    # Warm cache before peak hours
    def warm_peak_hours_cache(restaurant_id)
      return unless restaurant_id

      warm_restaurant_context(restaurant_id, tier: :hot)

      restaurant = Restaurant.find(restaurant_id)
      restaurant.menus.where(status: 'active').find_each do |menu|
        warm_menu_context(menu.id, tier: :hot)
      end
    end

    # Identify high priority cache warming opportunities
    def identify_high_priority_warming
      # Find restaurants with high activity but low cache hit rates
      # This would require cache metrics integration
      []
    end

    # Identify time-based warming opportunities
    def identify_time_based_warming
      current_hour = Time.current.hour

      case current_hour
      when 5..6 then ['morning_prep']
      when 10..11 then ['lunch_prep']
      when 16..17 then ['dinner_prep']
      when 21..22 then ['analytics_prep']
      else []
      end
    end

    # Identify business event warming opportunities
    def identify_business_event_warming
      # Check for upcoming events that would benefit from cache warming
      []
    end

    # Identify memory optimization opportunities
    def identify_memory_optimization_opportunities
      # Analyze cache usage patterns and suggest optimizations
      []
    end
  end
end
