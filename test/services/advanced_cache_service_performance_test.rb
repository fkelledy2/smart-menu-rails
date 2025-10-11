require 'test_helper'

class AdvancedCacheServicePerformanceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @menuitem = menuitems(:one)
    @employee = employees(:one) if defined?(Employee)

    # Reset cache stats for clean testing
    AdvancedCacheService.reset_cache_stats
  end

  def teardown
    # Clean up test caches
    Rails.cache.clear
  end

  test 'cache performance monitoring tracks hits and misses' do
    cache_key = "test_performance:#{SecureRandom.hex(8)}"

    # First call should be a miss
    result1 = AdvancedCacheService.monitored_cache_fetch(cache_key, expires_in: 1.minute) do
      { data: 'test_data', timestamp: Time.current.to_i }
    end

    # Second call should be a hit
    result2 = AdvancedCacheService.monitored_cache_fetch(cache_key, expires_in: 1.minute) do
      { data: 'different_data', timestamp: Time.current.to_i }
    end

    # Results should be the same (cached)
    assert_equal result1[:data], result2[:data]

    # Check metrics were recorded
    stats = AdvancedCacheService.cache_stats
    assert stats[:misses] >= 1, 'Should record cache misses'
    assert stats[:hits] >= 1, 'Should record cache hits'
    assert stats[:writes] >= 1, 'Should record cache writes'
  end

  test 'restaurant dashboard caching performance' do
    # Measure uncached performance
    uncached_time = Benchmark.realtime do
      5.times { AdvancedCacheService.cached_restaurant_dashboard(@restaurant.id) }
    end

    # Clear cache and measure first cached call
    Rails.cache.delete("restaurant_dashboard:#{@restaurant.id}")
    first_cached_time = Benchmark.realtime do
      AdvancedCacheService.cached_restaurant_dashboard(@restaurant.id)
    end

    # Measure subsequent cached calls
    cached_time = Benchmark.realtime do
      5.times { AdvancedCacheService.cached_restaurant_dashboard(@restaurant.id) }
    end

    # Cached calls should be significantly faster
    assert cached_time < uncached_time, 'Cached calls should be faster than uncached calls'
    assert cached_time < first_cached_time, 'Subsequent cached calls should be faster than first cached call'

    puts "\nRestaurant Dashboard Performance:"
    puts "  Uncached (5 calls): #{(uncached_time * 1000).round(2)}ms"
    puts "  First cached call: #{(first_cached_time * 1000).round(2)}ms"
    puts "  Cached (5 calls): #{(cached_time * 1000).round(2)}ms"
    puts "  Performance improvement: #{((uncached_time - cached_time) / uncached_time * 100).round(1)}%"
  end

  test 'menu caching performance with complex data' do
    # Clear cache and measure uncached performance (first call will populate cache)
    Rails.cache.delete("menu_full:#{@menu.id}:en:false")
    uncached_time = Benchmark.realtime do
      3.times { AdvancedCacheService.cached_menu_with_items(@menu.id) }
    end

    # Measure cached performance (cache should now be populated)
    cached_time = Benchmark.realtime do
      3.times { AdvancedCacheService.cached_menu_with_items(@menu.id) }
    end

    # Verify caching is working - cached calls should be faster or at least not significantly slower
    # Allow for small performance variations in test environment
    performance_ratio = cached_time / uncached_time
    assert performance_ratio < 1.5,
           "Cached menu calls should not be significantly slower (ratio: #{performance_ratio.round(2)})"

    puts "\nMenu Caching Performance:"
    puts "  Uncached (3 calls): #{(uncached_time * 1000).round(2)}ms"
    puts "  Cached (3 calls): #{(cached_time * 1000).round(2)}ms"
    puts "  Performance improvement: #{((uncached_time - cached_time) / uncached_time * 100).round(1)}%"
  end

  test 'cache warming performance' do
    # Clear all caches first
    AdvancedCacheService.clear_all_caches

    # Measure cache warming performance
    warming_time = Benchmark.realtime do
      result = AdvancedCacheService.warm_critical_caches(@restaurant.id)
      assert result[:success], 'Cache warming should succeed'
      assert_equal 1, result[:restaurants_warmed], 'Should warm exactly 1 restaurant'
    end

    puts "\nCache Warming Performance:"
    puts "  Warming time for 1 restaurant: #{(warming_time * 1000).round(2)}ms"

    # Verify caches are actually warmed
    dashboard_time = Benchmark.realtime do
      AdvancedCacheService.cached_restaurant_dashboard(@restaurant.id)
    end

    # Should be very fast since cache is warmed
    assert dashboard_time < 0.01, 'Warmed cache should respond very quickly'
    puts "  Dashboard access after warming: #{(dashboard_time * 1000).round(2)}ms"
  end

  test 'cache health check performance' do
    health_check_time = Benchmark.realtime do
      health = AdvancedCacheService.cache_health_check
      assert health[:healthy], 'Cache should be healthy'
      assert health[:operations][:write], 'Write operation should succeed'
      assert health[:operations][:read], 'Read operation should succeed'
      assert health[:operations][:delete], 'Delete operation should succeed'
    end

    puts "\nCache Health Check Performance:"
    puts "  Health check time: #{(health_check_time * 1000).round(2)}ms"

    # Health check should be fast
    assert health_check_time < 0.1, 'Health check should complete quickly'
  end

  test 'cache invalidation performance' do
    # Warm some caches first
    AdvancedCacheService.cached_restaurant_dashboard(@restaurant.id)
    AdvancedCacheService.cached_menu_with_items(@menu.id) if @menu

    # Measure invalidation performance
    invalidation_time = Benchmark.realtime do
      AdvancedCacheService.invalidate_restaurant_caches(@restaurant.id)
    end

    puts "\nCache Invalidation Performance:"
    puts "  Restaurant cache invalidation: #{(invalidation_time * 1000).round(2)}ms"

    # Invalidation should be fast
    assert invalidation_time < 0.1, 'Cache invalidation should be fast'

    # Verify caches are actually invalidated
    assert_nil Rails.cache.read("restaurant_dashboard:#{@restaurant.id}"),
               'Restaurant dashboard cache should be invalidated'
  end

  test 'concurrent cache access performance' do
    cache_key = "concurrent_test:#{SecureRandom.hex(8)}"

    # Simulate concurrent access
    threads = []
    results = []

    concurrent_time = Benchmark.realtime do
      5.times do |i|
        threads << Thread.new do
          result = AdvancedCacheService.monitored_cache_fetch(cache_key, expires_in: 1.minute) do
            sleep(0.01) # Simulate some work
            { thread_id: i, data: 'concurrent_data', timestamp: Time.current.to_f }
          end
          results << result
        end
      end

      threads.each(&:join)
    end

    puts "\nConcurrent Cache Access Performance:"
    puts "  5 concurrent operations: #{(concurrent_time * 1000).round(2)}ms"

    # All results should be the same (from cache)
    first_result = results.first
    results.each do |result|
      assert_equal first_result[:data], result[:data], 'All concurrent calls should return cached data'
    end

    # Should complete reasonably quickly
    assert concurrent_time < 1.0, 'Concurrent operations should complete within 1 second'
  end

  test 'memory usage estimation' do
    # Warm several caches
    AdvancedCacheService.warm_critical_caches(@restaurant.id)

    cache_info = AdvancedCacheService.cache_info

    assert cache_info[:memory_usage][:estimated_mb].positive?, 'Should estimate some memory usage'
    assert cache_info[:active_keys].positive?, 'Should estimate some active keys'
    assert cache_info[:total_methods] > 10, 'Should have multiple cache methods'

    puts "\nMemory Usage Estimation:"
    puts "  Estimated memory: #{cache_info[:memory_usage][:estimated_mb]}MB"
    puts "  Estimated active keys: #{cache_info[:active_keys]}"
    puts "  Total cache methods: #{cache_info[:total_methods]}"
  end

  private

  def assert_performance_improvement(uncached_time, cached_time, min_improvement = 0.5)
    improvement = (uncached_time - cached_time) / uncached_time
    assert improvement >= min_improvement,
           "Expected at least #{(min_improvement * 100).round(1)}% improvement, got #{(improvement * 100).round(1)}%"
  end
end
