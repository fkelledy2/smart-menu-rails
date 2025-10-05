# Advanced caching service for complex queries and data structures
class AdvancedCacheService
  class << self
    # Cache complex menu queries with localization
    def cached_menu_with_items(menu_id, locale: 'en', include_inactive: false)
      cache_key = "menu_full:#{menu_id}:#{locale}:#{include_inactive}"
      
      Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        menu = Menu.find(menu_id)
        restaurant = menu.restaurant
        
        {
          menu: serialize_menu(menu),
          restaurant: serialize_restaurant_basic(restaurant),
          sections: build_menu_sections(menu, locale, include_inactive),
          metadata: {
            total_items: menu.menusections.sum { |s| s.menuitems.count },
            active_items: menu.menusections.sum { |s| s.menuitems.where(status: 'active').count },
            locales: restaurant.restaurantlocales.pluck(:locale),
            cached_at: Time.current.iso8601
          }
        }
      end
    end

    # Cache restaurant dashboard data
    def cached_restaurant_dashboard(restaurant_id)
      Rails.cache.fetch("restaurant_dashboard:#{restaurant_id}", expires_in: 15.minutes) do
        restaurant = Restaurant.find(restaurant_id)
        
        # Use associations with fallback to regular queries
        active_menus = restaurant.menus.where(status: 'active')
        recent_orders = restaurant.respond_to?(:ordrs) ? restaurant.ordrs.where('created_at > ?', 24.hours.ago) : []
        staff = restaurant.employees
        tables = restaurant.tablesettings
        
        {
          restaurant: serialize_restaurant_full(restaurant),
          stats: {
            active_menus_count: active_menus.count,
            total_menus_count: restaurant.menus.count,
            recent_orders_count: recent_orders.count,
            staff_count: staff.count,
            table_count: tables.count,
            active_tables_count: tables.where(status: 'active').count
          },
          recent_activity: {
            recent_orders: recent_orders.first(5).map { |o| serialize_order_basic(o) },
            latest_menu_updates: active_menus.sort_by(&:updated_at).reverse.first(3).map { |m| serialize_menu_basic(m) }
          },
          quick_access: {
            primary_menu: active_menus.first&.then { |m| serialize_menu_basic(m) },
            online_staff: staff.select { |e| e.status == 'active' }.count
          }
        }
      end
    end

    # Cache order analytics with flexible date ranges
    def cached_order_analytics(restaurant_id, date_range = 30.days.ago..Time.current)
      cache_key = "order_analytics:#{restaurant_id}:#{date_range.begin.to_date}:#{date_range.end.to_date}"
      
      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        restaurant = Restaurant.find(restaurant_id)
        
        # Filter orders by date range using regular queries
        orders_in_range = if restaurant.respond_to?(:ordrs)
                           restaurant.ordrs.where(created_at: date_range)
                         else
                           []
                         end
        
        # Calculate analytics
        total_revenue = orders_in_range.sum { |o| o.total_amount || 0 }
        order_count = orders_in_range.count
        
        {
          period: {
            start_date: date_range.begin.to_date,
            end_date: date_range.end.to_date,
            days: (date_range.end.to_date - date_range.begin.to_date).to_i + 1
          },
          totals: {
            orders: order_count,
            revenue: total_revenue,
            average_order_value: order_count > 0 ? (total_revenue / order_count).round(2) : 0
          },
          trends: calculate_order_trends(orders_in_range),
          popular_items: calculate_popular_items(orders_in_range),
          daily_breakdown: calculate_daily_breakdown(orders_in_range, date_range)
        }
      end
    end

    # Cache menu performance analytics
    def cached_menu_performance(menu_id, days: 30)
      cache_key = "menu_performance:#{menu_id}:#{days}days"
      
      Rails.cache.fetch(cache_key, expires_in: 2.hours) do
        menu = Menu.find(menu_id)
        restaurant = menu.restaurant
        
        # Get orders for this menu in the specified period
        since_date = days.days.ago
        menu_orders = if restaurant.respond_to?(:ordrs)
                       restaurant.ordrs.where(menu_id: menu.id).where('created_at >= ?', since_date)
                     else
                       []
                     end
        
        # Analyze menu item performance
        item_performance = analyze_menu_item_performance(menu, menu_orders)
        
        {
          menu: serialize_menu_basic(menu),
          period_days: days,
          performance: {
            total_orders: menu_orders.count,
            total_revenue: menu_orders.sum { |o| o.total_amount || 0 },
            items_ordered: menu_orders.sum { |o| o.fetch_ordritems.sum(&:quantity) },
            unique_customers: menu_orders.map(&:customer_email).compact.uniq.count
          },
          item_analysis: item_performance,
          recommendations: generate_menu_recommendations(item_performance)
        }
      end
    end

    # Cache user activity summary
    def cached_user_activity(user_id, days: 7)
      Rails.cache.fetch("user_activity:#{user_id}:#{days}days", expires_in: 1.hour) do
        user = User.find(user_id)
        since_date = days.days.ago
        
        # Get user's restaurants and their recent activity
        restaurants = user.restaurants
        recent_activity = []
        
        restaurants.each do |restaurant|
          # Recent orders
          recent_orders = restaurant.respond_to?(:ordrs) ? restaurant.ordrs.where('created_at >= ?', since_date) : []
          
          # Recent menu updates
          recent_menu_updates = restaurant.menus.where('updated_at >= ?', since_date)
          
          recent_activity << {
            restaurant: serialize_restaurant_basic(restaurant),
            orders_count: recent_orders.count,
            menu_updates_count: recent_menu_updates.count,
            revenue: recent_orders.sum { |o| o.total_amount || 0 }
          }
        end
        
        {
          user: serialize_user_basic(user),
          period_days: days,
          summary: {
            total_restaurants: restaurants.count,
            active_restaurants: recent_activity.select { |r| r[:orders_count] > 0 }.count,
            total_orders: recent_activity.sum { |r| r[:orders_count] },
            total_revenue: recent_activity.sum { |r| r[:revenue] }
          },
          restaurants: recent_activity.sort_by { |r| r[:orders_count] }.reverse
        }
      end
    end

    # Invalidate related caches when data changes
    def invalidate_restaurant_caches(restaurant_id)
      Rails.cache.delete("restaurant_dashboard:#{restaurant_id}")
      Rails.cache.delete_matched("order_analytics:#{restaurant_id}:*")
      Rails.cache.delete_matched("menu_performance:*")
      
      # Invalidate user activity caches for restaurant owner
      begin
        restaurant = Restaurant.find(restaurant_id)
        Rails.cache.delete_matched("user_activity:#{restaurant.user_id}:*") if restaurant.user_id
      rescue ActiveRecord::RecordNotFound
        Rails.logger.warn("Restaurant #{restaurant_id} not found for cache invalidation")
      end
      
      Rails.logger.info("Invalidated caches for restaurant #{restaurant_id}")
    end

    def invalidate_menu_caches(menu_id)
      Rails.cache.delete_matched("menu_full:#{menu_id}:*")
      Rails.cache.delete_matched("menu_performance:#{menu_id}:*")
      
      Rails.logger.info("Invalidated caches for menu #{menu_id}")
    end

    def invalidate_user_caches(user_id)
      Rails.cache.delete_matched("user_activity:#{user_id}:*")
      
      # Also invalidate restaurant caches for user's restaurants
      begin
        user = User.find(user_id)
        user.restaurants.each do |restaurant|
          invalidate_restaurant_caches(restaurant.id)
        end
      rescue ActiveRecord::RecordNotFound
        Rails.logger.warn("User #{user_id} not found for cache invalidation")
      end
      
      Rails.logger.info("Invalidated caches for user #{user_id}")
    end

    private

    # Serialization methods for consistent cache data
    def serialize_restaurant_basic(restaurant)
      {
        id: restaurant.id,
        name: restaurant.name,
        status: restaurant.status,
        created_at: restaurant.created_at.iso8601
      }
    end

    def serialize_restaurant_full(restaurant)
      serialize_restaurant_basic(restaurant).merge(
        description: restaurant.description,
        address: restaurant.address,
        phone: restaurant.phone,
        email: restaurant.email,
        website: restaurant.website,
        updated_at: restaurant.updated_at.iso8601
      )
    end

    def serialize_menu_basic(menu)
      {
        id: menu.id,
        name: menu.name,
        status: menu.status,
        restaurant_id: menu.restaurant_id,
        created_at: menu.created_at.iso8601,
        updated_at: menu.updated_at.iso8601
      }
    end

    def serialize_menu(menu)
      serialize_menu_basic(menu).merge(
        description: menu.description,
        sections_count: menu.fetch_menusections.count
      )
    end

    def serialize_order_basic(order)
      {
        id: order.id,
        status: order.status,
        total_amount: order.total_amount,
        created_at: order.created_at.iso8601,
        items_count: order.fetch_ordritems.count
      }
    end

    def serialize_user_basic(user)
      {
        id: user.id,
        email: user.email,
        name: user.name,
        created_at: user.created_at.iso8601
      }
    end

    # Analysis methods
    def build_menu_sections(menu, locale, include_inactive)
      menu.menusections.map do |section|
        items = include_inactive ? section.menuitems : section.menuitems.where(status: 'active')
        
        {
          section: {
            id: section.id,
            name: section.name,
            position: section.sequence,
            status: section.status
          },
          items: items.map do |item|
            {
              id: item.id,
              name: item.respond_to?(:localised_name) ? item.localised_name(locale) : item.name,
              description: item.description,
              price: item.price,
              status: item.status,
              position: item.sequence,
              allergens: item.menuitem_allergyn_mappings.includes(:allergyn).map { |m| m.allergyn.symbol },
              sizes: item.menuitem_size_mappings.includes(:size).map { |m| m.size.name }
            }
          end
        }
      end
    end

    def calculate_order_trends(orders)
      return {} if orders.empty?
      
      # Group by day for trend analysis
      daily_orders = orders.group_by { |o| o.created_at.to_date }
      daily_revenue = daily_orders.transform_values { |day_orders| day_orders.sum { |o| o.total_amount || 0 } }
      
      {
        daily_orders: daily_orders.transform_values(&:count),
        daily_revenue: daily_revenue,
        peak_day: daily_orders.max_by { |_, orders| orders.count }&.first,
        average_daily_orders: daily_orders.values.sum(&:count) / daily_orders.keys.count.to_f
      }
    end

    def calculate_popular_items(orders)
      item_counts = Hash.new(0)
      item_revenue = Hash.new(0)
      
      orders.each do |order|
        order.fetch_ordritems.each do |item|
          menuitem = item.fetch_menuitem
          item_counts[menuitem.name] += item.quantity
          item_revenue[menuitem.name] += (item.price || 0) * item.quantity
        end
      end
      
      # Return top 10 by quantity and revenue
      {
        by_quantity: item_counts.sort_by { |_, count| -count }.first(10).to_h,
        by_revenue: item_revenue.sort_by { |_, revenue| -revenue }.first(10).to_h
      }
    end

    def calculate_daily_breakdown(orders, date_range)
      daily_data = {}
      
      # Initialize all days in range
      (date_range.begin.to_date..date_range.end.to_date).each do |date|
        daily_data[date] = { orders: 0, revenue: 0, items: 0 }
      end
      
      # Fill in actual data
      orders.each do |order|
        date = order.created_at.to_date
        daily_data[date][:orders] += 1
        daily_data[date][:revenue] += order.total_amount || 0
        daily_data[date][:items] += order.fetch_ordritems.sum(&:quantity)
      end
      
      daily_data
    end

    def analyze_menu_item_performance(menu, orders)
      item_stats = {}
      
      menu.fetch_menusections.each do |section|
        section.fetch_menuitems.each do |item|
          item_orders = orders.flat_map(&:fetch_ordritems).select { |oi| oi.menuitem_id == item.id }
          
          total_quantity = item_orders.sum(&:quantity)
          total_revenue = item_orders.sum { |oi| (oi.price || 0) * oi.quantity }
          
          item_stats[item.id] = {
            name: item.name,
            section: section.name,
            orders_count: item_orders.count,
            total_quantity: total_quantity,
            total_revenue: total_revenue,
            average_price: item_orders.any? ? total_revenue / total_quantity : 0
          }
        end
      end
      
      item_stats
    end

    def generate_menu_recommendations(item_performance)
      recommendations = []
      
      # Find underperforming items
      low_performers = item_performance.select { |_, stats| stats[:orders_count] == 0 }
      if low_performers.any?
        recommendations << {
          type: 'remove_items',
          message: "Consider removing #{low_performers.count} items with no orders",
          items: low_performers.keys
        }
      end
      
      # Find top performers
      top_performers = item_performance.sort_by { |_, stats| -stats[:total_revenue] }.first(3)
      if top_performers.any?
        recommendations << {
          type: 'promote_items',
          message: "Consider promoting your top #{top_performers.count} revenue generators",
          items: top_performers.map(&:first)
        }
      end
      
      recommendations
    end
  end
end
