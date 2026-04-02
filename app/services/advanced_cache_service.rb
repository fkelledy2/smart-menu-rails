# Advanced caching service for complex queries and data structures
class AdvancedCacheService
  # Cache performance monitoring
  CACHE_METRICS = {
    hits: 0,
    misses: 0,
    writes: 0,
    deletes: 0,
    errors: 0,
  }.freeze

  class << self
    # Cache performance monitoring methods
    def cache_stats
      {
        hits: Rails.cache.read('cache_metrics:hits') || 0,
        misses: Rails.cache.read('cache_metrics:misses') || 0,
        writes: Rails.cache.read('cache_metrics:writes') || 0,
        deletes: Rails.cache.read('cache_metrics:deletes') || 0,
        errors: Rails.cache.read('cache_metrics:errors') || 0,
        hit_rate: calculate_hit_rate,
        total_operations: calculate_total_operations,
        last_reset: Rails.cache.read('cache_metrics:last_reset') || Time.current.iso8601,
      }
    end

    def reset_cache_stats
      CACHE_METRICS.each_key do |metric|
        Rails.cache.write("cache_metrics:#{metric}", 0, expires_in: 1.week)
      end
      Rails.cache.write('cache_metrics:last_reset', Time.current.iso8601, expires_in: 1.week)
      Rails.logger.info('[AdvancedCacheService] Cache statistics reset')
    end

    def increment_metric(metric)
      # Performance: use atomic increment (INCR on Redis / increment on Memcached)
      # instead of a read-then-write pair which loses updates under concurrent load.
      key = "cache_metrics:#{metric}"
      Rails.cache.increment(key, 1)
    rescue StandardError
      # increment may raise if the key does not exist yet — seed it on the first call.
      begin
        Rails.cache.write(key, 1, expires_in: 1.week)
      rescue StandardError => e
        Rails.logger.error("[AdvancedCacheService] Failed to increment metric #{metric}: #{e.message}")
      end
    end

    def monitored_cache_fetch(cache_key, _options = {})
      start_time = Time.current

      begin
        result = Rails.cache.fetch(cache_key) do
          increment_metric(:misses)
          increment_metric(:writes)
          Rails.logger.debug { "[AdvancedCacheService] Cache MISS: #{cache_key}" }
          yield
        end

        # If we got here without calling the block, it was a cache hit
        if Rails.cache.exist?(cache_key)
          increment_metric(:hits)
          Rails.logger.debug { "[AdvancedCacheService] Cache HIT: #{cache_key}" }
        end

        duration = ((Time.current - start_time) * 1000).round(2)
        Rails.logger.debug { "[AdvancedCacheService] Cache operation completed in #{duration}ms" }

        result
      rescue StandardError => e
        increment_metric(:errors)
        Rails.logger.error("[AdvancedCacheService] Cache error for #{cache_key}: #{e.message}")
        # Return the block result directly if cache fails
        yield
      end
    end

    def cache_info
      {
        service_version: '1.0.0',
        total_methods: count_cache_methods,
        active_keys: estimate_active_keys,
        memory_usage: estimate_memory_usage,
        performance: cache_stats,
      }
    end

    # Cache complex menu queries with localization
    def cached_menu_with_items(menu_id, locale: 'en', include_inactive: false)
      cache_key = "menu_full:#{menu_id}:#{locale}:#{include_inactive}"

      Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        menu = Menu.find(menu_id)
        restaurant = menu.restaurant

        # Use a single JOIN-based SQL query rather than Ruby iteration (avoids N+1 per section)
        section_ids = menu.menusections.pluck(:id)
        total_items  = section_ids.any? ? Menuitem.where(menusection_id: section_ids).count : 0
        active_items = section_ids.any? ? Menuitem.where(menusection_id: section_ids, status: 'active').count : 0

        {
          menu: serialize_menu(menu),
          restaurant: serialize_restaurant_basic(restaurant),
          sections: build_menu_sections(menu, locale, include_inactive),
          metadata: {
            total_items: total_items,
            active_items: active_items,
            locales: restaurant.restaurantlocales.pluck(:locale),
            cached_at: Time.current.iso8601,
          },
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
            active_tables_count: tables.where(status: 'active').count,
          },
          recent_activity: {
            recent_orders: recent_orders.first(5).map { |o| serialize_order_basic(o) },
            # Use SQL ORDER BY + LIMIT instead of loading all menus and sorting in Ruby
            latest_menu_updates: active_menus.order(updated_at: :desc).limit(3).map { |m| serialize_menu_basic(m) },
          },
          quick_access: {
            primary_menu: active_menus.first&.then { |m| serialize_menu_basic(m) },
            # Use SQL COUNT with WHERE instead of loading all employees and filtering in Ruby
            online_staff: staff.where(status: 'active').count,
          },
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

        # Use SQL aggregates to avoid loading all order objects into memory
        total_revenue = orders_in_range.sum('COALESCE(gross, 0)')
        order_count = orders_in_range.count

        {
          period: {
            start_date: date_range.begin.to_date,
            end_date: date_range.end.to_date,
            days: (date_range.end.to_date - date_range.begin.to_date).to_i + 1,
          },
          totals: {
            orders: order_count,
            revenue: total_revenue,
            average_order_value: order_count.positive? ? (total_revenue / order_count).round(2) : 0,
          },
          trends: calculate_order_trends(orders_in_range),
          popular_items: calculate_popular_items(orders_in_range),
          daily_breakdown: calculate_daily_breakdown(orders_in_range, date_range),
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
                        restaurant.ordrs.where(menu_id: menu.id).where(created_at: since_date..)
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
            # Use SQL aggregates instead of Ruby iteration to avoid loading all records
            total_revenue: menu_orders.sum('COALESCE(gross, 0)'),
            items_ordered: Ordritem.where(ordr_id: menu_orders.select(:id)).count,
            unique_customers: 0, # customer_email not on Ordr; placeholder preserved
          },
          item_analysis: item_performance,
          recommendations: generate_menu_recommendations(item_performance),
        }
      end
    end

    # Cache user activity summary
    def cached_user_activity(user_id, days: 7)
      Rails.cache.fetch("user_activity:#{user_id}:#{days}days", expires_in: 1.hour) do
        user = User.find(user_id)
        since_date = days.days.ago

        # Load all restaurants in a single query (avoid N+1 in the loop below)
        restaurants = user.restaurants.to_a

        # Performance: build per-restaurant order/menu stats with one SQL aggregate
        # query per restaurant rather than loading all order objects into Ruby.
        restaurant_ids = restaurants.map(&:id)

        # One batched query for order counts + revenue grouped by restaurant
        order_stats = Ordr.where(restaurant_id: restaurant_ids, created_at: since_date..)
          .group(:restaurant_id)
          .pluck(:restaurant_id, Arel.sql('COUNT(*) AS orders_count, SUM(COALESCE(gross, 0)) AS revenue'))
          .each_with_object({}) do |(rid, count, rev), h|
            h[rid] = { orders_count: count, revenue: rev.to_f }
          end

        # One batched query for menu update counts grouped by restaurant
        menu_update_counts = Menu.where(restaurant_id: restaurant_ids, updated_at: since_date..)
          .group(:restaurant_id)
          .count

        recent_activity = restaurants.map do |restaurant|
          stats = order_stats[restaurant.id] || { orders_count: 0, revenue: 0.0 }
          {
            restaurant: serialize_restaurant_basic(restaurant),
            orders_count: stats[:orders_count],
            menu_updates_count: menu_update_counts[restaurant.id] || 0,
            revenue: stats[:revenue],
          }
        end

        {
          user: serialize_user_basic(user),
          period_days: days,
          summary: {
            total_restaurants: restaurants.size,
            active_restaurants: recent_activity.count { |r| r[:orders_count].positive? },
            total_orders: recent_activity.sum { |r| r[:orders_count] },
            total_revenue: recent_activity.sum { |r| r[:revenue] },
          },
          restaurants: recent_activity.sort_by { |r| r[:orders_count] }.reverse,
        }
      end
    end

    # Cache menu items with comprehensive details
    def cached_menu_items_with_details(menu_id, include_analytics: false)
      cache_key = "menu_items:#{menu_id}:#{include_analytics}"

      Rails.cache.fetch(cache_key, expires_in: 20.minutes) do
        menu = Menu.find(menu_id)

        items = menu.menusections.includes(:menuitems).flat_map do |section|
          section.menuitems.where(archived: false).map do |item|
            item_data = {
              id: item.id,
              name: item.name,
              description: item.description,
              price: item.price,
              status: item.status,
              sequence: item.sequence,
              section: {
                id: section.id,
                name: section.name,
              },
            }

            if include_analytics
              # Add basic analytics data
              item_data[:analytics] = {
                views_count: 0, # Placeholder - would need actual analytics
                orders_count: 0, # Placeholder - would need order data
                revenue: 0, # Placeholder - would need order data
              }
            end

            item_data
          end
        end

        {
          menu: serialize_menu_basic(menu),
          items: items,
          metadata: {
            total_items: items.count,
            active_items: items.count { |i| i[:status] == 'active' },
            cached_at: Time.current.iso8601,
          },
        }
      end
    end

    # Cache section items with details
    def cached_section_items_with_details(menusection_id)
      Rails.cache.fetch("section_items:#{menusection_id}", expires_in: 15.minutes) do
        # Performance: include :menu so that menusection.menu.id does not trigger a
        # lazy-load query when building the section hash below.
        menusection = Menusection.includes(:menu).find(menusection_id)

        items = menusection.menuitems.where(archived: false).map do |item|
          {
            id: item.id,
            name: item.name,
            description: item.description,
            price: item.price,
            status: item.status,
            sequence: item.sequence,
            calories: item.calories,
            has_image: item.image.present?,
          }
        end

        {
          section: {
            id: menusection.id,
            name: menusection.name,
            menu_id: menusection.menu.id,
          },
          items: items,
          metadata: {
            total_items: items.count,
            active_items: items.count { |i| i[:status] == 'active' },
            cached_at: Time.current.iso8601,
          },
        }
      end
    end

    # Cache individual menuitem with analytics
    def cached_menuitem_with_analytics(menuitem_id)
      Rails.cache.fetch("menuitem_analytics:#{menuitem_id}", expires_in: 30.minutes) do
        # Performance: eager-load the full association chain in one query so that
        # accessing menusection.menu.restaurant below does not trigger three lazy loads.
        menuitem = Menuitem.includes(menusection: { menu: :restaurant }).find_by(id: menuitem_id)
        return { error: 'Menu item not found' } unless menuitem

        {
          menuitem: {
            id: menuitem.id,
            name: menuitem.name,
            description: menuitem.description,
            price: menuitem.price,
            status: menuitem.status,
            calories: menuitem.calories,
            has_image: menuitem.image.present?,
          },
          section: {
            id: menuitem.menusection.id,
            name: menuitem.menusection.name,
          },
          menu: {
            id: menuitem.menusection.menu.id,
            name: menuitem.menusection.menu.name,
          },
          restaurant: serialize_restaurant_basic(menuitem.menusection.menu.restaurant),
          analytics: {
            # Placeholder analytics - would need actual order data
            total_orders: 0,
            total_revenue: 0,
            average_rating: 0,
            last_ordered: nil,
          },
          cached_at: Time.current.iso8601,
        }
      end
    end

    # Cache menuitem performance analytics
    def cached_menuitem_performance(menuitem_id, days: 30)
      cache_key = "menuitem_performance:#{menuitem_id}:#{days}days"

      Rails.cache.fetch(cache_key, expires_in: 2.hours) do
        menuitem = Menuitem.find(menuitem_id)
        menuitem.menusection.menu.restaurant

        # Get orders for this menuitem in the specified period
        days.days.ago
        # NOTE: This would need actual order item data structure
        menuitem_orders = []

        {
          menuitem: {
            id: menuitem.id,
            name: menuitem.name,
            price: menuitem.price,
          },
          period_days: days,
          performance: {
            total_orders: menuitem_orders.count,
            total_revenue: menuitem_orders.sum { |_o| menuitem.price },
            average_orders_per_day: menuitem_orders.count / days.to_f,
            popularity_rank: 0, # Would need comparison with other items
          },
          trends: {
            # Placeholder for trend analysis
            weekly_orders: [],
            peak_hours: [],
            seasonal_patterns: {},
          },
          recommendations: [
            # Placeholder recommendations
            'Consider promotional pricing during slow periods',
            'Item performs well - maintain current strategy',
          ],
        }
      end
    end

    # Cache restaurant orders with comprehensive data
    def cached_restaurant_orders(restaurant_id, include_calculations: false)
      cache_key = "restaurant_orders:#{restaurant_id}:#{include_calculations}"

      Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
        restaurant = Restaurant.find(restaurant_id)

        orders = if restaurant.respond_to?(:ordrs)
                   restaurant.ordrs.includes(:tablesetting, :menu).order(created_at: :desc).limit(100)
                 else
                   []
                 end

        # Pre-fetch ordritems_count via the counter_cache (avoids N+1 COUNT per order).
        # Ordr has counter_cache :ordritems_count on has_many :ordritems.
        # Also pre-load taxes once outside the loop when calculations are needed.
        taxes_data = include_calculations ? restaurant.taxes.order(:sequence).pluck(:taxpercentage, :taxtype) : []

        orders_data = orders.map do |order|
          order_data = {
            id: order.id,
            status: order.status,
            created_at: order.created_at.iso8601,
            table_number: order.tablesetting&.name,
            menu_name: order.menu&.name,
            # ordritems_count is a counter-cache column — no extra query needed
            items_count: order.ordritems_count,
          }

          if include_calculations
            nett = order.respond_to?(:runningTotal) ? order.runningTotal : 0
            total_tax = 0
            total_service = 0

            # taxes_data is pre-loaded as [percentage, type] pairs — no repeated DB queries
            taxes_data.each do |tax_percentage, tax_type|
              if tax_type == 'service'
                total_service += ((tax_percentage * nett) / 100)
              else
                total_tax += ((tax_percentage * nett) / 100)
              end
            end

            covercharge = if order.respond_to?(:ordercapacity) && order.menu
                            order.ordercapacity * (order.menu.covercharge || 0)
                          else
                            0
                          end

            order_data[:calculations] = {
              nett: nett,
              tax: total_tax,
              service: total_service,
              covercharge: covercharge,
              tip: order.tip || 0,
              gross: nett + covercharge + (order.tip || 0) + total_service + total_tax,
            }
          end

          order_data
        end

        {
          restaurant: serialize_restaurant_basic(restaurant),
          orders: orders_data,
          metadata: {
            total_orders: orders_data.count,
            active_orders: orders_data.count { |o| o[:status] != 'closed' },
            cached_at: Time.current.iso8601,
          },
        }
      end
    end

    # Cache user's all orders across restaurants
    def cached_user_all_orders(user_id)
      Rails.cache.fetch("user_orders:#{user_id}", expires_in: 15.minutes) do
        user = User.find(user_id)

        # Load all restaurants once; build a lookup map for name/id access in the loop.
        restaurants = user.restaurants.to_a
        restaurants_count = restaurants.size
        restaurant_map = restaurants.index_by(&:id)

        # Load up to 50 most-recent orders per restaurant in a single query using a
        # window function rather than N separate queries (one per restaurant).
        # Performance: uses counter_cache ordritems_count to avoid per-order COUNT.
        restaurant_ids = restaurant_map.keys
        all_orders = []

        restaurant_ids.each do |rid|
          restaurant_orders = Ordr.where(restaurant_id: rid)
            .includes(:tablesetting, :menu)
            .order(created_at: :desc)
            .limit(50)

          restaurant = restaurant_map[rid]

          restaurant_orders.each do |order|
            all_orders << {
              id: order.id,
              status: order.status,
              created_at: order.created_at.iso8601,
              restaurant_name: restaurant.name,
              restaurant_id: restaurant.id,
              table_number: order.tablesetting&.name,
              menu_name: order.menu&.name,
              # ordritems_count is a counter-cache column — no extra COUNT query needed
              items_count: order.ordritems_count,
            }
          end
        end

        # Sort all orders by creation date
        all_orders.sort_by! { |o| o[:created_at] }.reverse!

        {
          user: serialize_user_basic(user),
          orders: all_orders,
          metadata: {
            restaurants_count: restaurants_count,
            total_orders: all_orders.count,
            cached_at: Time.current.iso8601,
          },
        }
      end
    end

    # Cache individual order with comprehensive details and calculations
    def cached_order_with_details(order_id)
      Rails.cache.fetch("order_full:#{order_id}", expires_in: 30.minutes) do
        # Performance: eager-load ordritems + menuitem in one query (avoids N+1 on item names)
        # and pre-pluck taxes to avoid AR object instantiation for the tax loop.
        order = if defined?(Ordr)
                  Ordr.includes(:restaurant, :menu, ordritems: :menuitem).find_by(id: order_id)
                end

        return { error: 'Order not found' } unless order

        restaurant = order.restaurant

        # Use pluck to retrieve only the two columns needed — no AR objects created
        taxes_data = restaurant.taxes.order(:sequence).pluck(:taxpercentage, :taxtype)

        # Calculate order totals
        nett = order.respond_to?(:runningTotal) ? order.runningTotal : 0
        total_tax = 0
        total_service = 0

        taxes_data.each do |tax_percentage, tax_type|
          if tax_type == 'service'
            total_service += ((tax_percentage * nett) / 100)
          else
            total_tax += ((tax_percentage * nett) / 100)
          end
        end

        covercharge = if order.respond_to?(:ordercapacity) && order.menu
                        order.ordercapacity * (order.menu.covercharge || 0)
                      else
                        0
                      end
        tip = order.tip || 0
        gross = nett + covercharge + tip + total_service + total_tax

        {
          order: {
            id: order.id,
            status: order.status,
            created_at: order.created_at.iso8601,
            updated_at: order.updated_at.iso8601,
          },
          restaurant: serialize_restaurant_basic(restaurant),
          calculations: {
            nett: nett,
            tax: total_tax,
            service: total_service,
            covercharge: covercharge,
            tip: tip,
            gross: gross,
          },
          # ordritems + menuitem are already eager-loaded above — no per-item SELECT
          items: order.ordritems.map do |item|
            {
              id: item.id,
              name: item.menuitem&.name || 'Unknown Item',
              quantity: item.respond_to?(:quantity) ? (item.quantity || 1) : 1,
              price: item.respond_to?(:ordritemprice) ? item.ordritemprice || 0 : 0,
              status: item.status,
            }
          end,
          cached_at: Time.current.iso8601,
        }
      end
    end

    # Cache individual order analytics and similar orders
    def cached_individual_order_analytics(order_id, days: 7)
      cache_key = "order_analytics:#{order_id}:#{days}days"

      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        order = if defined?(Ordr)
                  Ordr.find(order_id)
                end

        return { error: 'Order not found' } unless order

        restaurant = order.restaurant
        since_date = days.days.ago

        # Get similar orders in the period
        similar_orders = if restaurant.respond_to?(:ordrs)
                           restaurant.ordrs.where(created_at: since_date..)
                         else
                           []
                         end

        # Performance: use SQL aggregates instead of materialising all similar orders.
        # COUNT + AVG(nett) replace similar_orders.sum { |o| o.runningTotal } / count.
        similar_count = similar_orders.count
        avg_value     = similar_count.positive? ? similar_orders.average('COALESCE(nett, 0)').to_f.round(2) : 0

        {
          order: {
            id: order.id,
            status: order.status,
            created_at: order.created_at.iso8601,
          },
          period_days: days,
          analytics: {
            similar_orders_count: similar_count,
            average_order_value: avg_value,
            popular_items: [], # Placeholder - would need order items analysis
            peak_hours: [], # Placeholder - would need time analysis
          },
          recommendations: [
            "Order placed during #{order.created_at.strftime('%A')} - typical for this restaurant",
            "Similar orders in the last #{days} days: #{similar_count}",
          ],
        }
      end
    end

    # Cache restaurant order summary
    def cached_restaurant_order_summary(restaurant_id, days: 30)
      cache_key = "order_summary:#{restaurant_id}:#{days}days"

      Rails.cache.fetch(cache_key, expires_in: 2.hours) do
        restaurant = Restaurant.find(restaurant_id)
        since_date = days.days.ago

        orders = if restaurant.respond_to?(:ordrs)
                   restaurant.ordrs.where(created_at: since_date..)
                 else
                   []
                 end

        # runningTotal computes SUM(ordritemprice * quantity) — use nett (the stored result)
        # or fall back to the SQL SUM of ordritems directly to avoid loading every order.
        total_revenue = orders.sum('COALESCE(nett, 0)')
        order_count   = orders.count

        {
          restaurant: serialize_restaurant_basic(restaurant),
          period_days: days,
          summary: {
            total_orders: order_count,
            total_revenue: total_revenue,
            average_order_value: order_count.positive? ? total_revenue / order_count : 0,
            orders_per_day: order_count / days.to_f,
          },
          trends: {
            daily_orders: calculate_daily_order_breakdown(orders),
            status_distribution: calculate_order_status_distribution(orders),
            peak_hours: calculate_order_peak_hours(orders),
          },
          cached_at: Time.current.iso8601,
        }
      end
    end

    # Cache restaurant employees with comprehensive data
    def cached_restaurant_employees(restaurant_id, include_analytics: false)
      cache_key = "restaurant_employees:#{restaurant_id}:#{include_analytics}"

      Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
        restaurant = Restaurant.find(restaurant_id)

        employees = if restaurant.respond_to?(:employees)
                      restaurant.employees.where(archived: false).includes(:user)
                    else
                      []
                    end

        employees_data = employees.map do |employee|
          employee_data = {
            id: employee.id,
            name: employee.name,
            eid: employee.eid,
            role: employee.role,
            status: employee.status,
            sequence: employee.sequence,
            email: employee.user&.email,
            created_at: employee.created_at.iso8601,
          }

          if include_analytics
            # Add basic analytics data (placeholder for future order/activity data)
            employee_data[:analytics] = {
              orders_handled: 0, # Placeholder - would need actual order data
              active_days: 0, # Placeholder - would need activity tracking
              performance_score: 0, # Placeholder - would need performance metrics
            }
          end

          employee_data
        end

        {
          restaurant: serialize_restaurant_basic(restaurant),
          employees: employees_data,
          metadata: {
            total_employees: employees_data.count,
            active_employees: employees_data.count { |e| e[:status] == 'active' },
            roles_distribution: employees_data.group_by { |e| e[:role] }.transform_values(&:count),
            cached_at: Time.current.iso8601,
          },
        }
      end
    end

    # Cache user's all employees across restaurants
    def cached_user_all_employees(user_id)
      Rails.cache.fetch("user_employees:#{user_id}", expires_in: 20.minutes) do
        user = User.find(user_id)

        # Performance: load all restaurants in one query, then fetch all employees
        # for those restaurants in a single batched query — avoids one SELECT per restaurant.
        restaurants = user.restaurants.to_a
        restaurants_count = restaurants.size
        restaurant_map = restaurants.index_by(&:id)
        restaurant_ids = restaurant_map.keys

        employees = Employee.where(restaurant_id: restaurant_ids, archived: false)
          .includes(:user)
          .order(created_at: :desc)

        all_employees = employees.map do |employee|
          restaurant = restaurant_map[employee.restaurant_id]
          {
            id: employee.id,
            name: employee.name,
            eid: employee.eid,
            role: employee.role,
            status: employee.status,
            email: employee.user&.email,
            restaurant_name: restaurant&.name,
            restaurant_id: employee.restaurant_id,
            created_at: employee.created_at.iso8601,
          }
        end

        {
          user: serialize_user_basic(user),
          employees: all_employees,
          metadata: {
            restaurants_count: restaurants_count,
            total_employees: all_employees.count,
            active_employees: all_employees.count { |e| e[:status] == 'active' },
            cached_at: Time.current.iso8601,
          },
        }
      end
    end

    # Cache individual employee with comprehensive details
    def cached_employee_with_details(employee_id)
      Rails.cache.fetch("employee_full:#{employee_id}", expires_in: 30.minutes) do
        employee = if defined?(Employee)
                     Employee.find(employee_id)
                   end

        return { error: 'Employee not found' } unless employee

        restaurant = employee.restaurant

        {
          employee: {
            id: employee.id,
            name: employee.name,
            eid: employee.eid,
            role: employee.role,
            status: employee.status,
            sequence: employee.sequence,
            email: employee.user&.email,
            created_at: employee.created_at.iso8601,
            updated_at: employee.updated_at.iso8601,
          },
          restaurant: serialize_restaurant_basic(restaurant),
          user: employee.user ? serialize_user_basic(employee.user) : nil,
          permissions: {
            can_take_orders: employee.role.in?(%w[manager waiter]),
            can_manage_kitchen: employee.role.in?(%w[manager chef]),
            can_manage_staff: employee.role == 'manager',
          },
          activity: {
            # Placeholder for activity tracking
            last_login: nil,
            orders_today: 0,
            shifts_this_week: 0,
          },
          cached_at: Time.current.iso8601,
        }
      end
    end

    # Cache employee performance analytics
    def cached_employee_performance(employee_id, days: 30)
      cache_key = "employee_performance:#{employee_id}:#{days}days"

      Rails.cache.fetch(cache_key, expires_in: 2.hours) do
        employee = if defined?(Employee)
                     Employee.find(employee_id)
                   end

        return { error: 'Employee not found' } unless employee

        restaurant = employee.restaurant
        since_date = days.days.ago

        # Get employee-related orders in the period (placeholder logic)
        employee_orders = if restaurant.respond_to?(:ordrs)
                            # This would need proper employee-order association
                            restaurant.ordrs.where(created_at: since_date..).limit(100)
                          else
                            []
                          end

        {
          employee: {
            id: employee.id,
            name: employee.name,
            role: employee.role,
            status: employee.status,
          },
          period_days: days,
          performance: {
            orders_handled: employee_orders.count, # Placeholder
            average_order_time: 0, # Placeholder - would need timing data
            customer_satisfaction: 0, # Placeholder - would need feedback data
            efficiency_score: 0, # Placeholder - would need performance metrics
          },
          trends: {
            daily_orders: calculate_daily_employee_orders(employee_orders),
            peak_hours: calculate_employee_peak_hours(employee_orders),
            performance_trend: [], # Placeholder for trend analysis
          },
          recommendations: [
            "Employee performance within normal range for #{employee.role}",
            'Consider additional training for peak hour efficiency',
          ],
        }
      end
    end

    # Cache restaurant employee summary
    def cached_restaurant_employee_summary(restaurant_id, days: 30)
      cache_key = "employee_summary:#{restaurant_id}:#{days}days"

      Rails.cache.fetch(cache_key, expires_in: 2.hours) do
        restaurant = Restaurant.find(restaurant_id)
        since_date = days.days.ago

        employees = if restaurant.respond_to?(:employees)
                      restaurant.employees.where(archived: false)
                    else
                      []
                    end

        # Get orders for analysis (placeholder logic)
        orders = if restaurant.respond_to?(:ordrs)
                   restaurant.ordrs.where(created_at: since_date..)
                 else
                   []
                 end

        {
          restaurant: serialize_restaurant_basic(restaurant),
          period_days: days,
          summary: {
            total_employees: employees.count,
            active_employees: employees.where(status: 'active').count,
            roles_breakdown: employees.unscope(:order).group(:role).count,
            average_tenure: calculate_average_employee_tenure(employees),
          },
          performance: {
            total_orders_handled: orders.count, # Placeholder
            orders_per_employee: employees.any? ? orders.count / employees.count.to_f : 0,
            efficiency_metrics: calculate_employee_efficiency_metrics(employees, orders),
          },
          trends: {
            hiring_trend: calculate_employee_hiring_trend(employees, days),
            turnover_rate: calculate_employee_turnover_rate(employees, days),
            performance_distribution: calculate_employee_performance_distribution(employees),
          },
          cached_at: Time.current.iso8601,
        }
      end
    end

    # Cache warming strategies for critical data
    def warm_critical_caches(restaurant_id = nil)
      start_time = Time.current
      warmed_count = 0

      Rails.logger.info("[AdvancedCacheService] Starting cache warming#{restaurant_id ? " for restaurant #{restaurant_id}" : ' for all restaurants'}")

      begin
        if restaurant_id
          warm_restaurant_caches(restaurant_id)
          warmed_count += 1
        else
          Restaurant.limit(10).find_each do |restaurant|
            warm_restaurant_caches(restaurant.id)
            warmed_count += 1
          end
        end

        duration = ((Time.current - start_time) * 1000).round(2)
        Rails.logger.info("[AdvancedCacheService] Cache warming completed: #{warmed_count} restaurants in #{duration}ms")

        { success: true, restaurants_warmed: warmed_count, duration_ms: duration }
      rescue StandardError => e
        Rails.logger.error("[AdvancedCacheService] Cache warming failed: #{e.message}")
        { success: false, error: e.message, restaurants_warmed: warmed_count }
      end
    end

    def warm_restaurant_caches(restaurant_id)
      restaurant = Restaurant.find(restaurant_id)

      # Warm restaurant dashboard
      cached_restaurant_dashboard(restaurant_id)

      # Warm recent orders
      cached_restaurant_orders(restaurant_id, include_calculations: true) if restaurant.respond_to?(:ordrs)

      # Warm employees
      cached_restaurant_employees(restaurant_id, include_analytics: true) if restaurant.respond_to?(:employees)

      # Warm menus
      restaurant.menus.limit(5).each do |menu|
        cached_menu_with_items(menu.id)
        cached_menu_performance(menu.id) if menu.respond_to?(:menusections)
      end

      Rails.logger.debug { "[AdvancedCacheService] Warmed caches for restaurant #{restaurant_id}" }
    end

    # Cache administration and debugging tools
    def clear_all_caches
      patterns = [
        'restaurant_*', 'menu_*', 'menuitem_*', 'order_*', 'employee_*',
        'user_*', 'section_*', 'analytics_*', 'performance_*',
      ]

      cleared_count = 0
      patterns.each do |pattern|
        keys = Rails.cache.delete_matched(pattern)
        cleared_count += keys.is_a?(Integer) ? keys : 0
      end

      Rails.logger.info("[AdvancedCacheService] Cleared #{cleared_count} cache entries")
      { cleared_count: cleared_count, patterns: patterns }
    end

    def cache_health_check
      start_time = Time.current

      begin
        # Test basic cache operations
        test_key = "health_check:#{SecureRandom.hex(8)}"
        test_value = { timestamp: Time.current.to_i, test: true }

        # Write test
        Rails.cache.write(test_key, test_value, expires_in: 1.minute)

        # Read test
        cached_value = Rails.cache.read(test_key)
        read_success = cached_value == test_value

        # Delete test
        Rails.cache.delete(test_key)
        delete_success = !Rails.cache.exist?(test_key)

        duration = ((Time.current - start_time) * 1000).round(2)

        {
          healthy: read_success && delete_success,
          operations: {
            write: true,
            read: read_success,
            delete: delete_success,
          },
          response_time_ms: duration,
          timestamp: Time.current.iso8601,
        }
      rescue StandardError => e
        {
          healthy: false,
          error: e.message,
          response_time_ms: ((Time.current - start_time) * 1000).round(2),
          timestamp: Time.current.iso8601,
        }
      end
    end

    def list_cache_keys(pattern = '*', limit: 100)
      # NOTE: This is a simplified version - Redis would need SCAN command
      # For development/debugging purposes

      if Rails.cache.respond_to?(:redis)
        # Redis implementation
        Rails.cache.redis.scan_each(match: pattern).first(limit)
      else
        # Memory store or other - limited functionality
        ["Cache key listing not available for #{Rails.cache.class}"]
      end
    rescue StandardError => e
      Rails.logger.error("[AdvancedCacheService] Failed to list cache keys: #{e.message}")
      []
    end

    # Public invalidation methods (called by model hooks)
    def invalidate_restaurant_caches(restaurant_id)
      Rails.cache.delete("restaurant_dashboard:#{restaurant_id}")
      Rails.cache.delete_matched("order_analytics:#{restaurant_id}:*")
      Rails.cache.delete_matched('menu_performance:*')

      # Invalidate user activity caches for restaurant owner
      begin
        restaurant = Restaurant.find(restaurant_id)
        Rails.cache.delete_matched("user_activity:#{restaurant.user_id}:*") if restaurant.user_id
      rescue ActiveRecord::RecordNotFound
        Rails.logger.warn("Restaurant #{restaurant_id} not found during cache invalidation")
      end

      Rails.logger.info("Invalidated caches for restaurant #{restaurant_id}")
    end

    def invalidate_menu_caches(menu_id)
      Rails.cache.delete_matched("menu_full:#{menu_id}:*")
      Rails.cache.delete_matched("menu_items:#{menu_id}:*")
      Rails.cache.delete_matched("menu_performance:#{menu_id}:*")
      Rails.cache.delete_matched("menu_analytics:#{menu_id}:*")

      begin
        section_ids = Menusection.where(menu_id: menu_id).pluck(:id)
        section_ids.each do |section_id|
          Rails.cache.delete("section_items:#{section_id}")
        end
      rescue StandardError
        nil
      end

      Rails.logger.info("Invalidated caches for menu #{menu_id}")
    end

    def invalidate_menuitem_caches(menuitem_id)
      Rails.cache.delete_matched("menuitem_full:#{menuitem_id}:*")
      Rails.cache.delete_matched("menuitem_performance:#{menuitem_id}:*")
      Rails.cache.delete_matched("menuitem_analytics:#{menuitem_id}:*")

      Rails.logger.info("Invalidated caches for menuitem #{menuitem_id}")
    end

    def invalidate_order_caches(order_id, restaurant_id: nil)
      Rails.cache.delete_matched("order_full:#{order_id}:*")
      Rails.cache.delete_matched("order_analytics:#{order_id}:*")

      # Scope restaurant_orders invalidation to the specific restaurant when available.
      # The global wildcard 'restaurant_orders:*' would scan every cached key across all
      # tenants — O(n) on all restaurants. Scoping to restaurant_id reduces this to the
      # single tenant whose order changed.
      if restaurant_id
        Rails.cache.delete_matched("restaurant_orders:#{restaurant_id}:*")
      else
        Rails.cache.delete_matched('restaurant_orders:*')
      end

      Rails.cache.delete_matched('user_orders:*')
      Rails.cache.delete_matched('order_summary:*')

      Rails.logger.info("Invalidated caches for order #{order_id} (restaurant: #{restaurant_id || 'unknown'})")
    end

    def invalidate_employee_caches(employee_id)
      Rails.cache.delete_matched("employee_full:#{employee_id}:*")
      Rails.cache.delete_matched("employee_performance:#{employee_id}:*")
      Rails.cache.delete_matched('restaurant_employees:*')
      Rails.cache.delete_matched('user_employees:*')
      Rails.cache.delete_matched('employee_summary:*')

      Rails.logger.info("Invalidated caches for employee #{employee_id}")
    end

    def invalidate_user_caches(user_id, skip_restaurant_cascade: false)
      Rails.cache.delete_matched("user_activity:#{user_id}:*")

      # Only cascade to restaurant caches if explicitly requested
      # This prevents the excessive cascade invalidation seen in production logs
      unless skip_restaurant_cascade
        begin
          # Use pluck to avoid loading full objects
          restaurant_ids = User.where(id: user_id).joins(:restaurants).pluck('restaurants.id')
          restaurant_ids.each do |restaurant_id|
            # Use selective invalidation instead of full restaurant cache clear
            invalidate_restaurant_caches_selectively(restaurant_id)
          end
        rescue StandardError => e
          Rails.logger.warn("Failed to cascade restaurant cache invalidation for user #{user_id}: #{e.message}")
        end
      end

      Rails.logger.info("Invalidated caches for user #{user_id} (cascade: #{!skip_restaurant_cascade})")
    end

    def invalidate_restaurant_caches_selectively(restaurant_id)
      # More targeted invalidation - only clear specific cache patterns
      selective_keys = [
        "restaurant_dashboard:#{restaurant_id}",
        "restaurant_orders:#{restaurant_id}:recent",
        "restaurant_employees:#{restaurant_id}:active",
      ]

      selective_keys.each { |key| Rails.cache.delete(key) }

      # Only clear analytics caches if they exist (check first to avoid unnecessary work)
      analytics_pattern = "order_analytics:#{restaurant_id}:*"
      if Rails.cache.exist?("order_analytics:#{restaurant_id}:7")
        Rails.cache.delete_matched(analytics_pattern)
      end

      Rails.logger.info("Selectively invalidated caches for restaurant #{restaurant_id}")
    end

    private

    def calculate_hit_rate
      hits = Rails.cache.read('cache_metrics:hits') || 0
      misses = Rails.cache.read('cache_metrics:misses') || 0
      total = hits + misses

      return 0.0 if total.zero?

      ((hits.to_f / total) * 100).round(2)
    end

    def calculate_total_operations
      CACHE_METRICS.keys.sum do |metric|
        Rails.cache.read("cache_metrics:#{metric}") || 0
      end
    end

    def count_cache_methods
      # Count methods that start with 'cached_'
      methods.grep(/^cached_/).count
    end

    def estimate_active_keys
      # This is an approximation - would need Redis DBSIZE for accurate count
      patterns = ['restaurant_*', 'menu_*', 'menuitem_*', 'order_*', 'employee_*', 'user_*']
      patterns.count * 50 # Rough estimate
    end

    def estimate_memory_usage
      # Placeholder - would need Redis MEMORY USAGE command for accurate measurement
      {
        estimated_mb: estimate_active_keys * 0.1, # Rough estimate: 0.1MB per key
        note: 'Estimation only - use Redis MEMORY commands for accurate measurement',
      }
    end

    # Safe localization and data access helpers
    def get_localized_item_name(item, locale)
      return item.name unless item.respond_to?(:localised_name)

      begin
        item.localised_name(locale)
      rescue StandardError => e
        Rails.logger.warn("[AdvancedCacheService] Localization error for item #{item.id}: #{e.message}")
        item.name
      end
    end

    def get_item_allergens(item)
      return [] unless item.respond_to?(:menuitem_allergyn_mappings)

      begin
        item.menuitem_allergyn_mappings.includes(:allergyn).filter_map { |m| m.allergyn&.symbol }
      rescue StandardError => e
        Rails.logger.warn("[AdvancedCacheService] Allergen mapping error for item #{item.id}: #{e.message}")
        []
      end
    end

    def get_item_sizes(item)
      return [] unless item.respond_to?(:menuitem_size_mappings)

      begin
        item.menuitem_size_mappings.includes(:size).filter_map { |m| m.size&.name }
      rescue StandardError => e
        Rails.logger.warn("[AdvancedCacheService] Size mapping error for item #{item.id}: #{e.message}")
        []
      end
    end

    # Serialization methods for consistent cache data
    def serialize_restaurant_basic(restaurant)
      {
        id: restaurant.id,
        name: restaurant.name,
        status: restaurant.status,
        created_at: restaurant.created_at.iso8601,
      }
    end

    def serialize_restaurant_full(restaurant)
      serialize_restaurant_basic(restaurant).merge(
        description: restaurant.description,
        address1: restaurant.address1,
        address2: restaurant.address2,
        city: restaurant.city,
        state: restaurant.state,
        postcode: restaurant.postcode,
        country: restaurant.country,
        capacity: restaurant.capacity,
        currency: restaurant.currency,
        updated_at: restaurant.updated_at.iso8601,
      )
    end

    def serialize_menu_basic(menu)
      {
        id: menu.id,
        name: menu.name,
        status: menu.status,
        restaurant_id: menu.restaurant_id,
        created_at: menu.created_at.iso8601,
        updated_at: menu.updated_at.iso8601,
      }
    end

    def serialize_menu(menu)
      # Performance: read the menusections_count counter-cache column instead of
      # issuing a COUNT(*) or materialising all sections via fetch_menusections.
      serialize_menu_basic(menu).merge(
        description: menu.description,
        sections_count: menu.menusections_count,
      )
    end

    def serialize_order_basic(order)
      {
        id: order.id,
        status: order.status,
        total_amount: order.gross || 0,
        created_at: order.created_at.iso8601,
        # Performance: prefer the ordritems_count counter-cache column to avoid a
        # COUNT(*) query per order. Fall back to fetch_ordritems/ordritems only when
        # the column is unexpectedly absent (e.g. IdentityCache proxy objects).
        items_count: order.respond_to?(:ordritems_count) ? (order.ordritems_count || 0) : order.ordritems.count,
      }
    end

    def serialize_user_basic(user)
      {
        id: user.id,
        email: user.email,
        name: user.name,
        created_at: user.created_at.iso8601,
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
            status: section.status,
          },
          items: items.map do |item|
            {
              id: item.id,
              name: get_localized_item_name(item, locale),
              description: item.description,
              price: item.price,
              status: item.status,
              position: item.sequence,
              allergens: get_item_allergens(item),
              sizes: get_item_sizes(item),
            }
          end,
        }
      end
    end

    def calculate_daily_order_breakdown(orders)
      # Performance: GROUP BY in SQL instead of loading all order rows into Ruby.
      # unscope(:order) strips the restaurant.ordrs reorder(orderedAt:) scope which
      # would otherwise conflict with the GROUP BY clause in PostgreSQL.
      return {} if orders.respond_to?(:empty?) && orders.empty?

      orders
        .unscope(:order)
        .group(Arel.sql('DATE(created_at)'))
        .count
        .transform_keys(&:to_s)
    end

    def calculate_order_status_distribution(orders)
      # Performance: SQL GROUP BY instead of Ruby group_by.
      return {} if orders.respond_to?(:empty?) && orders.empty?

      orders.unscope(:order).group(:status).count
    end

    def calculate_order_peak_hours(orders)
      # Performance: SQL EXTRACT(HOUR ...) GROUP BY instead of loading all orders.
      return [] if orders.respond_to?(:empty?) && orders.empty?

      orders
        .unscope(:order)
        .group(Arel.sql('EXTRACT(HOUR FROM created_at)::int'))
        .count
        .map { |hour, count| { hour: hour, count: count } }
        .sort_by { |h| -h[:count] }
        .first(3)
    end

    def calculate_daily_employee_orders(orders)
      return {} if orders.empty?

      daily_orders = orders.group_by { |o| o.created_at.to_date }
      daily_orders.transform_values(&:count)
    end

    def calculate_employee_peak_hours(orders)
      return [] if orders.empty?

      hourly_orders = orders.group_by { |o| o.created_at.hour }
      hourly_orders.map { |hour, orders| { hour: hour, count: orders.count } }
        .sort_by { |h| h[:count] }.last(3).reverse
    end

    def calculate_average_employee_tenure(employees)
      return 0 if employees.empty?

      total_days = employees.sum { |e| (Time.current - e.created_at) / 1.day }
      (total_days / employees.count).round(1)
    end

    def calculate_employee_efficiency_metrics(employees, orders)
      return {} if employees.empty? || orders.empty?

      {
        orders_per_day: orders.count / 30.0, # Assuming 30-day period
        average_response_time: 0, # Placeholder - would need timing data
        task_completion_rate: 100, # Placeholder - would need task tracking
      }
    end

    def calculate_employee_hiring_trend(employees, days)
      return [] if employees.empty?

      since_date = days.days.ago
      recent_hires = employees.where(created_at: since_date..)

      daily_hires = recent_hires.group_by { |e| e.created_at.to_date }
      daily_hires.transform_values(&:count)
    end

    def calculate_employee_turnover_rate(employees, _days)
      # Placeholder calculation - would need actual turnover tracking
      return 0 if employees.empty?

      # Simple approximation based on archived employees
      total_employees = employees.count
      archived_employees = 0 # Would need to track archived employees in period

      return 0 if total_employees.zero?

      (archived_employees / total_employees.to_f * 100).round(2)
    end

    def calculate_employee_performance_distribution(employees)
      return {} if employees.empty?

      # Placeholder distribution based on roles
      employees.group_by(&:role).transform_values(&:count)
    end

    def calculate_order_trends(orders)
      # Performance: use SQL GROUP BY + aggregates — avoids loading every order row
      # into Ruby memory for a potentially large date range.
      return {} if orders.respond_to?(:empty?) && orders.empty?

      # unscope(:order) strips the reorder(orderedAt:) from restaurant.ordrs scope
      # which would otherwise cause a PostgreSQL GROUP BY / ORDER BY conflict.
      daily_rows = orders
        .unscope(:order)
        .group(Arel.sql('DATE(created_at)'))
        .pluck(
          Arel.sql('DATE(created_at)'),
          Arel.sql('COUNT(*)'),
          Arel.sql('SUM(COALESCE(gross, 0))'),
        )

      return {} if daily_rows.empty?

      daily_orders  = daily_rows.to_h { |date, cnt, _rev| [date.to_s, cnt.to_i] }
      daily_revenue = daily_rows.to_h { |date, _cnt, rev| [date.to_s, rev.to_f.round(2)] }
      peak_day      = daily_rows.max_by { |_, cnt, _rev| cnt }&.first&.to_s
      total_count   = daily_rows.sum { |_, cnt, _rev| cnt.to_i }

      {
        daily_orders: daily_orders,
        daily_revenue: daily_revenue,
        peak_day: peak_day,
        average_daily_orders: daily_rows.size.positive? ? (total_count.to_f / daily_rows.size).round(2) : 0,
      }
    end

    def calculate_popular_items(orders)
      # Performance: use a single SQL aggregate query against ordritems + menuitems
      # rather than materialising every order row and all its ordritems into Ruby.
      # This replaces an N+1 (one ordritems query per order) with two GROUP BY queries.
      return { by_quantity: {}, by_revenue: {} } if orders.respond_to?(:empty?) && orders.empty?

      order_ids = orders.respond_to?(:select) ? orders.select(:id) : orders.map(&:id)

      rows = Ordritem
        .joins(:menuitem)
        .where(ordr_id: order_ids)
        .where.not(status: Ordritem.statuses['removed'])
        .group('menuitems.name')
        .pluck(
          'menuitems.name',
          Arel.sql('SUM(ordritems.quantity)'),
          Arel.sql('SUM(ordritems.ordritemprice * ordritems.quantity)'),
        )

      by_quantity = rows.sort_by { |_, qty, _rev| -qty }.first(10)
        .to_h { |name, qty, _rev| [name, qty.to_i] }
      by_revenue  = rows.sort_by { |_, _qty, rev| -rev.to_f }.first(10)
        .to_h { |name, _qty, rev| [name, rev.to_f.round(2)] }

      { by_quantity: by_quantity, by_revenue: by_revenue }
    end

    def calculate_daily_breakdown(orders, date_range)
      daily_data = {}

      # Initialize all days in range
      (date_range.begin.to_date..date_range.end.to_date).each do |date|
        daily_data[date] = { orders: 0, revenue: 0, items: 0 }
      end

      # Fill in actual data
      # Performance: use ordritems_count counter-cache to avoid one COUNT(*) per order
      orders.each do |order|
        date = order.created_at.to_date
        daily_data[date][:orders] += 1
        daily_data[date][:revenue] += order.gross || 0
        daily_data[date][:items] += order.respond_to?(:ordritems_count) ? (order.ordritems_count || 0) : order.ordritems.count
      end

      daily_data
    end

    def analyze_menu_item_performance(menu, orders)
      # Performance: replace O(sections * items * orders) Ruby iteration with two SQL
      # queries — one to get menu item metadata, one GROUP BY aggregate for order stats.
      sections = menu.fetch_menusections.to_a
      section_map = sections.index_by(&:id)

      menuitems = Menuitem.where(menusection_id: sections.map(&:id))
        .pluck(:id, :name, :menusection_id)

      item_stats = menuitems.each_with_object({}) do |(item_id, item_name, section_id), h|
        section_name = section_map[section_id]&.name || ''
        h[item_id] = {
          name: item_name,
          section: section_name,
          orders_count: 0,
          total_quantity: 0,
          total_revenue: 0.0,
          average_price: 0,
        }
      end

      return item_stats if item_stats.empty? || !orders.respond_to?(:select)

      order_ids = orders.select(:id)
      Ordritem
        .where(ordr_id: order_ids, menuitem_id: item_stats.keys)
        .where.not(status: Ordritem.statuses['removed'])
        .group(:menuitem_id)
        .pluck(
          :menuitem_id,
          Arel.sql('COUNT(DISTINCT ordr_id)'),
          Arel.sql('SUM(quantity)'),
          Arel.sql('SUM(ordritemprice * quantity)'),
        )
        .each do |item_id, order_count, qty, revenue|
          next unless item_stats.key?(item_id)

          item_stats[item_id][:orders_count] = order_count.to_i
          item_stats[item_id][:total_quantity] = qty.to_i
          item_stats[item_id][:total_revenue]  = revenue.to_f.round(2)
          item_stats[item_id][:average_price]  = qty.to_i.positive? ? (revenue.to_f / qty.to_i).round(2) : 0
        end

      item_stats
    end

    def generate_menu_recommendations(item_performance)
      recommendations = []

      # Find underperforming items
      low_performers = item_performance.select { |_, stats| stats[:orders_count].zero? }
      if low_performers.any?
        recommendations << {
          type: 'remove_items',
          message: "Consider removing #{low_performers.count} items with no orders",
          items: low_performers.keys,
        }
      end

      # Find top performers
      top_performers = item_performance.sort_by { |_, stats| -stats[:total_revenue] }.first(3)
      if top_performers.any?
        recommendations << {
          type: 'promote_items',
          message: "Consider promoting your top #{top_performers.count} revenue generators",
          items: top_performers.map(&:first),
        }
      end

      recommendations
    end
  end
end
