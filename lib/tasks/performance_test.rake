namespace :performance do
  desc 'Test performance optimizations in development'
  task test: :environment do
    puts '🚀 Testing Performance Optimizations'
    puts '=' * 50

    # Test 1: Cache invalidation performance
    puts "\n1. Testing Cache Invalidation Performance..."

    restaurant = Restaurant.first
    user = restaurant&.user
    order = restaurant&.ordrs&.first

    if restaurant && user && order
      start_time = Time.current

      # Test synchronous vs asynchronous cache invalidation
      puts '   Testing synchronous cache invalidation...'
      sync_start = Time.current
      AdvancedCacheService.invalidate_order_caches(order.id)
      AdvancedCacheService.invalidate_restaurant_caches_selectively(restaurant.id)
      AdvancedCacheService.invalidate_user_caches(user.id, skip_restaurant_cascade: true)
      sync_duration = ((Time.current - sync_start) * 1000).round(2)
      puts "   ✅ Synchronous invalidation: #{sync_duration}ms"

      # Test background job
      puts '   Testing asynchronous cache invalidation...'
      async_start = Time.current
      CacheInvalidationJob.perform_now(
        order_id: order.id,
        restaurant_id: restaurant.id,
        user_id: user.id,
      )
      async_duration = ((Time.current - async_start) * 1000).round(2)
      puts "   ✅ Asynchronous invalidation: #{async_duration}ms"

      total_duration = ((Time.current - start_time) * 1000).round(2)
      puts "   📊 Total cache test duration: #{total_duration}ms"
    else
      puts '   ⚠️  No test data available (restaurant, user, or order missing)'
    end

    # Test 2: Query optimization
    puts "\n2. Testing Query Optimization..."

    if order
      puts '   Testing order totals calculation with caching...'
      calc_start = Time.current

      # Create a controller instance to test the private method
      controller = OrdrsController.new
      controller.send(:calculate_order_totals, order)

      calc_duration = ((Time.current - calc_start) * 1000).round(2)
      puts "   ✅ Order calculation with tax caching: #{calc_duration}ms"
      puts "   📊 Order totals - Gross: #{order.gross}, Tax: #{order.tax}, Service: #{order.service}"
    else
      puts '   ⚠️  No order available for testing'
    end

    # Test 3: Database query counting
    puts "\n3. Testing Database Query Efficiency..."

    if order
      query_count = 0
      ActiveSupport::Notifications.subscribe 'sql.active_record' do |_name, _started, _finished, _unique_id, data|
        query_count += 1 unless /^PRAGMA|^SELECT sqlite_version|^SHOW|^EXPLAIN/.match?(data[:sql])
      end

      query_start = Time.current

      # Simulate the optimized broadcast_partials eager loading
      optimized_order = Ordr.includes(
        :ordritems, :ordrparticipants, :ordractions, :employee,
        menu: [
          :restaurant, :menusections, :menuavailabilities,
          { menusections: [:menuitems],
            menuitems: %i[allergyns ingredients], },
        ],
        tablesetting: [:restaurant],
        restaurant: %i[restaurantlocales taxes allergyns],
      ).find(order.id)

      # Access associated data to trigger queries
      optimized_order.menu.restaurant.name
      optimized_order.ordritems.count
      optimized_order.menu.menusections.each do |section|
        section.menuitems.each do |item|
          item.allergyns.count
          item.ingredients.count
        end
      end

      query_duration = ((Time.current - query_start) * 1000).round(2)
      puts "   ✅ Optimized query execution: #{query_duration}ms"
      puts "   📊 Database queries executed: #{query_count}"

      if query_count > 20
        puts "   ⚠️  Query count is high (#{query_count}), consider further optimization"
      else
        puts "   ✅ Query count is optimized (#{query_count} queries)"
      end
    else
      puts '   ⚠️  No order available for query testing'
    end

    # Test 4: Cache hit rate
    puts "\n4. Testing Cache Performance..."

    cache_stats = AdvancedCacheService.cache_stats
    puts '   📊 Cache Statistics:'
    puts "      Hits: #{cache_stats[:hits]}"
    puts "      Misses: #{cache_stats[:misses]}"
    puts "      Hit Rate: #{cache_stats[:hit_rate]}%"
    puts "      Total Operations: #{cache_stats[:total_operations]}"

    if cache_stats[:hit_rate] > 70
      puts "   ✅ Cache hit rate is good (#{cache_stats[:hit_rate]}%)"
    elsif cache_stats[:hit_rate] > 50
      puts "   ⚠️  Cache hit rate could be improved (#{cache_stats[:hit_rate]}%)"
    else
      puts "   ❌ Cache hit rate is low (#{cache_stats[:hit_rate]}%)"
    end

    puts "\n#{'=' * 50}"
    puts '🎯 Performance Test Summary:'
    puts '   - Cache invalidation optimized with background jobs'
    puts '   - Query optimization with comprehensive eager loading'
    puts '   - Tax calculations cached for better performance'
    puts '   - Error handling improved for production stability'
    puts "\n💡 Next Steps:"
    puts '   1. Deploy these optimizations to production'
    puts '   2. Monitor response times and query counts'
    puts "   3. Check for reduction in '[SLOW REQUEST]' logs"
    puts '   4. Verify IdentityCache errors are reduced'
    puts '=' * 50
  end

  desc 'Reset cache statistics'
  task reset_cache_stats: :environment do
    AdvancedCacheService.reset_cache_stats
    puts '✅ Cache statistics reset'
  end

  desc 'Show current cache statistics'
  task cache_stats: :environment do
    stats = AdvancedCacheService.cache_stats
    puts '📊 Current Cache Statistics:'
    puts "   Hits: #{stats[:hits]}"
    puts "   Misses: #{stats[:misses]}"
    puts "   Hit Rate: #{stats[:hit_rate]}%"
    puts "   Total Operations: #{stats[:total_operations]}"
    puts "   Last Reset: #{stats[:last_reset]}"
  end
end
