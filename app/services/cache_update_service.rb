# frozen_string_literal: true

# L1 Cache Optimization: Cache Update Service
# Updates cache entries instead of invalidating them for better performance
class CacheUpdateService
  include ActionView::Helpers::DateHelper

  class << self
    # Update restaurant cache with fresh data
    def update_restaurant_cache(restaurant, operation: :update)
      Rails.logger.info("[CacheUpdateService] Updating restaurant cache for restaurant #{restaurant.id}")

      case operation
      when :update
        update_restaurant_data(restaurant)
      when :create
        warm_new_restaurant_cache(restaurant)
      when :destroy
        invalidate_restaurant_cache(restaurant)
      end
    end

    # Update menu cache with fresh data
    def update_menu_cache(menu, operation: :update)
      Rails.logger.info("[CacheUpdateService] Updating menu cache for menu #{menu.id}")

      case operation
      when :update
        update_menu_data(menu)
      when :create
        warm_new_menu_cache(menu)
      when :destroy
        invalidate_menu_cache(menu)
      end
    end

    # Update order cache with fresh data
    def update_order_cache(order, operation: :update)
      Rails.logger.info("[CacheUpdateService] Updating order cache for order #{order.id}")

      case operation
      when :update, :create
        update_order_data(order)
      when :destroy
        invalidate_order_cache(order)
      end
    end

    # Update employee cache with fresh data
    def update_employee_cache(employee, operation: :update)
      Rails.logger.info("[CacheUpdateService] Updating employee cache for employee #{employee.id}")

      case operation
      when :update
        update_employee_data(employee)
      when :create
        warm_new_employee_cache(employee)
      when :destroy
        invalidate_employee_cache(employee)
      end
    end

    # Partial cache update for menu items
    def update_menu_item_cache(menu_item, operation: :update)
      Rails.logger.debug { "[CacheUpdateService] Updating menu item cache for item #{menu_item.id}" }

      menu = menu_item.menusection.menu

      case operation
      when :update
        update_menu_item_in_cache(menu_item, menu)
      when :create
        add_menu_item_to_cache(menu_item, menu)
      when :destroy
        remove_menu_item_from_cache(menu_item, menu)
      end
    end

    # Batch update multiple cache entries
    def batch_update_cache(updates)
      Rails.logger.info("[CacheUpdateService] Batch updating #{updates.size} cache entries")

      updates.each do |update|
        case update[:type]
        when :restaurant
          update_restaurant_cache(update[:object], operation: update[:operation])
        when :menu
          update_menu_cache(update[:object], operation: update[:operation])
        when :order
          update_order_cache(update[:object], operation: update[:operation])
        when :employee
          update_employee_cache(update[:object], operation: update[:operation])
        when :menu_item
          update_menu_item_cache(update[:object], operation: update[:operation])
        end
      end
    end

    # Smart cache update based on changed attributes
    def smart_update_cache(model, changed_attributes)
      Rails.logger.debug { "[CacheUpdateService] Smart cache update for #{model.class.name}##{model.id}" }

      case model.class.name
      when 'Restaurant'
        update_restaurant_smart(model, changed_attributes)
      when 'Menu'
        update_menu_smart(model, changed_attributes)
      when 'Menuitem'
        update_menu_item_smart(model, changed_attributes)
      when 'Ordr'
        update_order_smart(model, changed_attributes)
      when 'Employee'
        update_employee_smart(model, changed_attributes)
      end
    end

    # Update cache with computed deltas (incremental updates)
    def update_cache_with_delta(cache_key, delta_data)
      Rails.logger.debug { "[CacheUpdateService] Updating cache with delta: #{cache_key}" }

      existing_data = Rails.cache.read(cache_key)
      return unless existing_data

      updated_data = apply_delta_to_cache_data(existing_data, delta_data)
      Rails.cache.write(cache_key, updated_data, expires_in: 30.minutes)
    end

    private

    # Update restaurant data in cache
    def update_restaurant_data(restaurant)
      # Update restaurant dashboard
      dashboard_key = "restaurant_dashboard:#{restaurant.id}"
      fresh_dashboard = AdvancedCacheService.cached_restaurant_dashboard(restaurant.id)
      Rails.cache.write(dashboard_key, fresh_dashboard, expires_in: 15.minutes)

      # Update restaurant basic info in related caches
      update_restaurant_references(restaurant)

      # Update user activity cache if this affects it
      if restaurant.respond_to?(:user_id) && restaurant.user_id
        user_activity_key = "user_activity:#{restaurant.user_id}:7days"
        Rails.cache.delete(user_activity_key) # Will be regenerated on next access
      end
    end

    # Update menu data in cache
    def update_menu_data(menu)
      restaurant = menu.restaurant
      locales = restaurant.restaurantlocales.pluck(:locale).presence || ['en']

      # Update menu with items for all locales
      locales.each do |locale|
        [true, false].each do |include_inactive|
          menu_key = "menu_full:#{menu.id}:#{locale}:#{include_inactive}"
          fresh_menu = AdvancedCacheService.cached_menu_with_items(menu.id, locale: locale,
                                                                            include_inactive: include_inactive,)
          Rails.cache.write(menu_key, fresh_menu, expires_in: 30.minutes)
        end
      end

      # Update menu items cache
      menu_items_key = "menu_items:#{menu.id}:true"
      fresh_items = AdvancedCacheService.cached_menu_items_with_details(menu.id, include_analytics: true)
      Rails.cache.write(menu_items_key, fresh_items, expires_in: 20.minutes)

      # Update restaurant dashboard (menu count might have changed)
      update_restaurant_data(restaurant)
    end

    # Update order data in cache
    def update_order_data(order)
      restaurant = order.restaurant

      # Update individual order cache
      order_key = "order_full:#{order.id}"
      fresh_order = AdvancedCacheService.cached_order_with_details(order.id)
      Rails.cache.write(order_key, fresh_order, expires_in: 30.minutes)

      # Update restaurant orders cache
      restaurant_orders_key = "restaurant_orders:#{restaurant.id}:true"
      fresh_orders = AdvancedCacheService.cached_restaurant_orders(restaurant.id, include_calculations: true)
      Rails.cache.write(restaurant_orders_key, fresh_orders, expires_in: 10.minutes)

      # Update restaurant dashboard
      update_restaurant_data(restaurant)

      # Update order analytics (invalidate for regeneration)
      Rails.cache.delete_matched("order_analytics:#{restaurant.id}:*")
      Rails.cache.delete_matched("order_summary:#{restaurant.id}:*")
    end

    # Update employee data in cache
    def update_employee_data(employee)
      restaurant = employee.restaurant

      # Update individual employee cache
      employee_key = "employee_full:#{employee.id}"
      fresh_employee = AdvancedCacheService.cached_employee_with_details(employee.id)
      Rails.cache.write(employee_key, fresh_employee, expires_in: 30.minutes)

      # Update restaurant employees cache
      restaurant_employees_key = "restaurant_employees:#{restaurant.id}:true"
      fresh_employees = AdvancedCacheService.cached_restaurant_employees(restaurant.id, include_analytics: true)
      Rails.cache.write(restaurant_employees_key, fresh_employees, expires_in: 15.minutes)

      # Update restaurant dashboard
      update_restaurant_data(restaurant)
    end

    # Warm cache for new restaurant
    def warm_new_restaurant_cache(restaurant)
      IntelligentCacheWarmingService.warm_restaurant_context(restaurant.id, tier: :hot)
    end

    # Warm cache for new menu
    def warm_new_menu_cache(menu)
      IntelligentCacheWarmingService.warm_menu_context(menu.id, tier: :hot)
      update_restaurant_data(menu.restaurant)
    end

    # Warm cache for new employee
    def warm_new_employee_cache(employee)
      update_employee_data(employee)
    end

    # Invalidate restaurant cache
    def invalidate_restaurant_cache(restaurant)
      CacheDependencyService.invalidate_for_model_change(restaurant, :destroy)
    end

    # Invalidate menu cache
    def invalidate_menu_cache(menu)
      CacheDependencyService.invalidate_for_model_change(menu, :destroy)
    end

    # Invalidate order cache
    def invalidate_order_cache(order)
      CacheDependencyService.invalidate_for_model_change(order, :destroy)
    end

    # Invalidate employee cache
    def invalidate_employee_cache(employee)
      CacheDependencyService.invalidate_for_model_change(employee, :destroy)
    end

    # Update menu item within existing menu cache
    def update_menu_item_in_cache(menu_item, menu)
      # Update menu_full caches
      restaurant = menu.restaurant
      locales = restaurant.restaurantlocales.pluck(:locale).presence || ['en']

      locales.each do |locale|
        [true, false].each do |include_inactive|
          menu_key = "menu_full:#{menu.id}:#{locale}:#{include_inactive}"
          menu_cache = Rails.cache.read(menu_key)

          next unless menu_cache && menu_cache[:sections]

          # Find and update the specific item
          menu_cache[:sections].each do |section|
            next unless section[:id] == menu_item.menusection.id

            item_index = section[:items].find_index { |item| item[:id] == menu_item.id }
            if item_index
              section[:items][item_index] = serialize_menu_item(menu_item)
              Rails.cache.write(menu_key, menu_cache, expires_in: 30.minutes)
            end
          end
        end
      end

      # Update section items cache
      section_key = "section_items:#{menu_item.menusection.id}"
      section_cache = Rails.cache.read(section_key)
      return unless section_cache && section_cache[:items]

      item_index = section_cache[:items].find_index { |item| item[:id] == menu_item.id }
      if item_index
        section_cache[:items][item_index] = serialize_menu_item_basic(menu_item)
        Rails.cache.write(section_key, section_cache, expires_in: 15.minutes)
      end
    end

    # Add menu item to existing cache
    def add_menu_item_to_cache(_menu_item, menu)
      # Similar to update but adds the item instead of updating
      update_menu_data(menu) # Full refresh for new items
    end

    # Remove menu item from existing cache
    def remove_menu_item_from_cache(menu_item, menu)
      # Remove from menu_full caches
      restaurant = menu.restaurant
      locales = restaurant.restaurantlocales.pluck(:locale).presence || ['en']

      locales.each do |locale|
        [true, false].each do |include_inactive|
          menu_key = "menu_full:#{menu.id}:#{locale}:#{include_inactive}"
          menu_cache = Rails.cache.read(menu_key)

          next unless menu_cache && menu_cache[:sections]

          menu_cache[:sections].each do |section|
            if section[:id] == menu_item.menusection.id
              section[:items].reject! { |item| item[:id] == menu_item.id }
              Rails.cache.write(menu_key, menu_cache, expires_in: 30.minutes)
            end
          end
        end
      end

      # Update section items cache
      section_key = "section_items:#{menu_item.menusection.id}"
      section_cache = Rails.cache.read(section_key)
      if section_cache && section_cache[:items]
        section_cache[:items].reject! { |item| item[:id] == menu_item.id }
        Rails.cache.write(section_key, section_cache, expires_in: 15.minutes)
      end
    end

    # Smart restaurant update based on changed attributes
    def update_restaurant_smart(restaurant, changed_attributes)
      if changed_attributes.include?('name') || changed_attributes.include?('status')
        # Full update needed
        update_restaurant_data(restaurant)
      else
        # Partial update
        dashboard_key = "restaurant_dashboard:#{restaurant.id}"
        dashboard_cache = Rails.cache.read(dashboard_key)
        if dashboard_cache
          # Update only the changed fields
          dashboard_cache[:restaurant] = serialize_restaurant_basic(restaurant)
          Rails.cache.write(dashboard_key, dashboard_cache, expires_in: 15.minutes)
        end
      end
    end

    # Smart menu update based on changed attributes
    def update_menu_smart(menu, changed_attributes)
      if changed_attributes.include?('name') || changed_attributes.include?('status')
        # Full update needed
        update_menu_data(menu)
      else
        # Partial update possible
        update_menu_references(menu)
      end
    end

    # Smart menu item update based on changed attributes
    def update_menu_item_smart(menu_item, changed_attributes)
      menu = menu_item.menusection.menu

      if changed_attributes.include?('name') || changed_attributes.include?('price') || changed_attributes.include?('status')
        # Update the item in existing caches
        update_menu_item_in_cache(menu_item, menu)
      end
    end

    # Smart order update based on changed attributes
    def update_order_smart(order, changed_attributes)
      if changed_attributes.include?('status') || changed_attributes.include?('tip')
        # Update order and related caches
        update_order_data(order)
      end
    end

    # Smart employee update based on changed attributes
    def update_employee_smart(employee, changed_attributes)
      if changed_attributes.include?('name') || changed_attributes.include?('role') || changed_attributes.include?('status')
        # Update employee and related caches
        update_employee_data(employee)
      end
    end

    # Update restaurant references in other caches
    def update_restaurant_references(restaurant)
      # This would update restaurant info in user caches, order caches, etc.
      # Implementation depends on specific cache structures
    end

    # Update menu references in other caches
    def update_menu_references(menu)
      # Update menu info in restaurant dashboard and other related caches
      restaurant_dashboard_key = "restaurant_dashboard:#{menu.restaurant.id}"
      dashboard_cache = Rails.cache.read(restaurant_dashboard_key)

      unless dashboard_cache && dashboard_cache[:recent_activity] && dashboard_cache[:recent_activity][:latest_menu_updates]
        return
      end

      # Update menu info in recent activity
      menu_update = dashboard_cache[:recent_activity][:latest_menu_updates].find { |m| m[:id] == menu.id }
      if menu_update
        menu_update.merge!(serialize_menu_basic(menu))
        Rails.cache.write(restaurant_dashboard_key, dashboard_cache, expires_in: 15.minutes)
      end
    end

    # Apply delta changes to existing cache data
    def apply_delta_to_cache_data(existing_data, delta_data)
      # Deep merge delta changes into existing data
      case existing_data
      when Hash
        existing_data.deep_merge(delta_data)
      when Array
        # Handle array updates (add, remove, update items)
        apply_array_delta(existing_data, delta_data)
      else
        delta_data
      end
    end

    # Apply delta changes to array data
    def apply_array_delta(existing_array, delta_data)
      return existing_array unless delta_data.is_a?(Hash)

      result = existing_array.dup

      if delta_data[:add]
        result.concat(delta_data[:add])
      end

      delta_data[:remove]&.each do |item_to_remove|
        result.reject! { |item| item[:id] == item_to_remove[:id] }
      end

      delta_data[:update]&.each do |item_to_update|
        index = result.find_index { |item| item[:id] == item_to_update[:id] }
        result[index] = item_to_update if index
      end

      result
    end

    # Serialize menu item for cache
    def serialize_menu_item(menu_item)
      {
        id: menu_item.id,
        name: menu_item.name,
        description: menu_item.description,
        price: menu_item.price,
        status: menu_item.status,
        sequence: menu_item.sequence,
        calories: menu_item.calories,
        has_image: menu_item.image.present?,
        updated_at: menu_item.updated_at.iso8601,
      }
    end

    # Serialize menu item basic info for cache
    def serialize_menu_item_basic(menu_item)
      {
        id: menu_item.id,
        name: menu_item.name,
        price: menu_item.price,
        status: menu_item.status,
        sequence: menu_item.sequence,
      }
    end

    # Serialize restaurant basic info for cache
    def serialize_restaurant_basic(restaurant)
      {
        id: restaurant.id,
        name: restaurant.name,
        status: restaurant.status,
        currency: restaurant.currency,
        updated_at: restaurant.updated_at.iso8601,
      }
    end

    # Serialize menu basic info for cache
    def serialize_menu_basic(menu)
      {
        id: menu.id,
        name: menu.name,
        status: menu.status,
        updated_at: menu.updated_at.iso8601,
      }
    end
  end
end
