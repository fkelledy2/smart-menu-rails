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
      current_value = Rails.cache.read("cache_metrics:#{metric}") || 0
      Rails.cache.write("cache_metrics:#{metric}", current_value + 1, expires_in: 1.week)
    rescue StandardError => e
      Rails.logger.error("[AdvancedCacheService] Failed to increment metric #{metric}: #{e.message}")
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

        {
          menu: serialize_menu(menu),
          restaurant: serialize_restaurant_basic(restaurant),
          sections: build_menu_sections(menu, locale, include_inactive),
          metadata: {
            total_items: menu.menusections.sum { |s| s.menuitems.count },
            active_items: menu.menusections.sum { |s| s.menuitems.where(status: 'active').count },
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
            latest_menu_updates: active_menus.sort_by(&:updated_at).last(3).reverse.map { |m| serialize_menu_basic(m) },
          },
          quick_access: {
            primary_menu: active_menus.first&.then { |m| serialize_menu_basic(m) },
            online_staff: staff.count { |e| e.status == 'active' },
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

        # Calculate analytics
        total_revenue = orders_in_range.sum { |o| o.gross || 0 }
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
            total_revenue: menu_orders.sum { |o| o.gross || 0 },
            items_ordered: menu_orders.sum do |o|
              o.respond_to?(:fetch_ordritems) ? o.fetch_ordritems.count : o.ordritems.count
            end,
            unique_customers: menu_orders.filter_map do |o|
              o.respond_to?(:customer_email) ? o.customer_email : nil
            end.uniq.count,
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

        # Get user's restaurants and their recent activity
        restaurants = user.restaurants
        recent_activity = []

        restaurants.each do |restaurant|
          # Recent orders
          recent_orders = restaurant.respond_to?(:ordrs) ? restaurant.ordrs.where(created_at: since_date..) : []

          # Recent menu updates
          recent_menu_updates = restaurant.menus.where(updated_at: since_date..)

          recent_activity << {
            restaurant: serialize_restaurant_basic(restaurant),
            orders_count: recent_orders.count,
            menu_updates_count: recent_menu_updates.count,
            revenue: recent_orders.sum { |o| o.gross || 0 },
          }
        end

        {
          user: serialize_user_basic(user),
          period_days: days,
          summary: {
            total_restaurants: restaurants.count,
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
        menusection = Menusection.find(menusection_id)

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
        menuitem = Menuitem.find(menuitem_id)

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
                   restaurant.ordrs.includes(:ordritems, :tablesetting, :menu).order(created_at: :desc).limit(100)
                 else
                   []
                 end

        orders_data = orders.map do |order|
          order_data = {
            id: order.id,
            status: order.status,
            created_at: order.created_at.iso8601,
            table_number: order.tablesetting&.name,
            menu_name: order.menu&.name,
            items_count: order.ordritems.count,
          }

          if include_calculations
            # Add tax calculations
            taxes = restaurant.taxes.order(:sequence)
            nett = order.respond_to?(:runningTotal) ? order.runningTotal : 0
            total_tax = 0
            total_service = 0

            taxes.each do |tax|
              if tax.taxtype == 'service'
                total_service += ((tax.taxpercentage * nett) / 100)
              else
                total_tax += ((tax.taxpercentage * nett) / 100)
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
        all_orders = []
        restaurants_count = 0

        user.restaurants.each do |restaurant|
          restaurants_count += 1
          next unless restaurant.respond_to?(:ordrs)

          restaurant_orders = restaurant.ordrs.includes(:tablesetting, :menu)
            .order(created_at: :desc).limit(50)

          restaurant_orders.each do |order|
            all_orders << {
              id: order.id,
              status: order.status,
              created_at: order.created_at.iso8601,
              restaurant_name: restaurant.name,
              restaurant_id: restaurant.id,
              table_number: order.tablesetting&.name,
              menu_name: order.menu&.name,
              items_count: order.ordritems.count,
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
        order = if defined?(Ordr)
                  Ordr.find(order_id)
                else
                  # Fallback if Ordr model doesn't exist
                  nil
                end

        return { error: 'Order not found' } unless order

        restaurant = order.restaurant
        taxes = restaurant.taxes.order(:sequence)

        # Calculate order totals
        nett = order.respond_to?(:runningTotal) ? order.runningTotal : 0
        total_tax = 0
        total_service = 0

        taxes.each do |tax|
          if tax.taxtype == 'service'
            total_service += ((tax.taxpercentage * nett) / 100)
          else
            total_tax += ((tax.taxpercentage * nett) / 100)
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
          items: order.ordritems.map do |item|
            {
              id: item.id,
              name: item.menuitem&.name || 'Unknown Item',
              quantity: 1, # Ordritem doesn't have quantity field, assume 1
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

        {
          order: {
            id: order.id,
            status: order.status,
            created_at: order.created_at.iso8601,
          },
          period_days: days,
          analytics: {
            similar_orders_count: similar_orders.count,
            average_order_value: if similar_orders.any?
                                   similar_orders.sum do |o|
                                     o.respond_to?(:runningTotal) ? o.runningTotal : 0
                                   end / similar_orders.count
                                 else
                                   0
                                 end,
            popular_items: [], # Placeholder - would need order items analysis
            peak_hours: [], # Placeholder - would need time analysis
          },
          recommendations: [
            "Order placed during #{order.created_at.strftime('%A')} - typical for this restaurant",
            "Similar orders in the last #{days} days: #{similar_orders.count}",
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

        total_revenue = orders.sum { |o| o.respond_to?(:runningTotal) ? o.runningTotal : 0 }

        {
          restaurant: serialize_restaurant_basic(restaurant),
          period_days: days,
          summary: {
            total_orders: orders.count,
            total_revenue: total_revenue,
            average_order_value: orders.any? ? total_revenue / orders.count : 0,
            orders_per_day: orders.count / days.to_f,
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
        all_employees = []
        restaurants_count = 0

        user.restaurants.each do |restaurant|
          restaurants_count += 1
          next unless restaurant.respond_to?(:employees)

          restaurant_employees = restaurant.employees.where(archived: false).includes(:user)

          restaurant_employees.each do |employee|
            all_employees << {
              id: employee.id,
              name: employee.name,
              eid: employee.eid,
              role: employee.role,
              status: employee.status,
              email: employee.user&.email,
              restaurant_name: restaurant.name,
              restaurant_id: restaurant.id,
              created_at: employee.created_at.iso8601,
            }
          end
        end

        # Sort all employees by creation date
        all_employees.sort_by! { |e| e[:created_at] }.reverse!

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
            roles_breakdown: employees.group(:role).count,
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

    def invalidate_order_caches(order_id)
      Rails.cache.delete_matched("order_full:#{order_id}:*")
      Rails.cache.delete_matched("order_analytics:#{order_id}:*")
      Rails.cache.delete_matched('restaurant_orders:*')
      Rails.cache.delete_matched('user_orders:*')
      Rails.cache.delete_matched('order_summary:*')

      Rails.logger.info("Invalidated caches for order #{order_id}")
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
      serialize_menu_basic(menu).merge(
        description: menu.description,
        sections_count: menu.fetch_menusections.count,
      )
    end

    def serialize_order_basic(order)
      {
        id: order.id,
        status: order.status,
        total_amount: order.gross || 0,
        created_at: order.created_at.iso8601,
        items_count: order.respond_to?(:fetch_ordritems) ? order.fetch_ordritems.count : order.ordritems.count,
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
      return {} if orders.empty?

      daily_orders = orders.group_by { |o| o.created_at.to_date }
      daily_orders.transform_values(&:count)
    end

    def calculate_order_status_distribution(orders)
      return {} if orders.empty?

      orders.group_by(&:status).transform_values(&:count)
    end

    def calculate_order_peak_hours(orders)
      return [] if orders.empty?

      hourly_orders = orders.group_by { |o| o.created_at.hour }
      hourly_orders.map { |hour, orders| { hour: hour, count: orders.count } }
        .sort_by { |h| h[:count] }.last(3).reverse
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
      return {} if orders.empty?

      # Group by day for trend analysis
      daily_orders = orders.group_by { |o| o.created_at.to_date }
      daily_revenue = daily_orders.transform_values { |day_orders| day_orders.sum { |o| o.gross || 0 } }

      {
        daily_orders: daily_orders.transform_values(&:count),
        daily_revenue: daily_revenue,
        peak_day: daily_orders.max_by { |_, orders| orders.count }&.first,
        average_daily_orders: daily_orders.values.sum(&:count) / daily_orders.keys.count.to_f,
      }
    end

    def calculate_popular_items(orders)
      item_counts = Hash.new(0)
      item_revenue = Hash.new(0)

      orders.each do |order|
        ordritems = order.respond_to?(:fetch_ordritems) ? order.fetch_ordritems : order.ordritems
        ordritems.each do |item|
          menuitem = item.respond_to?(:fetch_menuitem) ? item.fetch_menuitem : item.menuitem
          next unless menuitem

          # Handle case where menuitem might be an array (take first element)
          menuitem = menuitem.first if menuitem.is_a?(Array)
          next unless menuitem.respond_to?(:name)

          item_counts[menuitem.name] += 1 # Assume quantity 1
          item_revenue[menuitem.name] += item.respond_to?(:ordritemprice) ? (item.ordritemprice || 0) : 0
        end
      end

      # Return top 10 by quantity and revenue
      {
        by_quantity: item_counts.sort_by { |_, count| -count }.first(10).to_h,
        by_revenue: item_revenue.sort_by { |_, revenue| -revenue }.first(10).to_h,
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
        daily_data[date][:revenue] += order.gross || 0
        daily_data[date][:items] += order.respond_to?(:fetch_ordritems) ? order.fetch_ordritems.count : order.ordritems.count
      end

      daily_data
    end

    def analyze_menu_item_performance(menu, orders)
      item_stats = {}

      menu.fetch_menusections.each do |section|
        menuitems = section.respond_to?(:fetch_menuitems) ? section.fetch_menuitems : section.menuitems
        menuitems.each do |item|
          all_ordritems = orders.flat_map { |o| o.respond_to?(:fetch_ordritems) ? o.fetch_ordritems : o.ordritems }
          item_orders = all_ordritems.select { |oi| oi.menuitem_id == item.id }

          total_quantity = item_orders.count # Assume quantity 1 per order item
          total_revenue = item_orders.sum { |oi| oi.respond_to?(:ordritemprice) ? (oi.ordritemprice || 0) : 0 }

          item_stats[item.id] = {
            name: item.name,
            section: section.name,
            orders_count: item_orders.count,
            total_quantity: total_quantity,
            total_revenue: total_revenue,
            average_price: item_orders.any? ? total_revenue / total_quantity : 0,
          }
        end
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
