# frozen_string_literal: true

namespace :query_cache do
  desc "Warm up query caches with commonly accessed data"
  task warm: :environment do
    puts "🔥 Starting query cache warming..."
    
    start_time = Time.current
    success = CacheWarmingService.warm_all
    execution_time = Time.current - start_time
    
    if success
      puts "✅ Cache warming completed successfully in #{execution_time.round(2)}s"
    else
      puts "❌ Cache warming failed"
      exit 1
    end
  end

  desc "Clear all query caches"
  task clear: :environment do
    puts "🧹 Clearing all query caches..."
    
    if Rails.cache.respond_to?(:delete_matched)
      Rails.cache.delete_matched("query_cache:*")
      puts "✅ All query caches cleared"
    else
      puts "⚠️  Cache backend doesn't support pattern deletion"
      puts "   Clearing individual cache entries..."
      
      # Clear known cache patterns
      cache_patterns = [
        'query_cache:metrics_summary:*',
        'query_cache:system_metrics:*',
        'query_cache:recent_metrics:*',
        'query_cache:analytics_dashboard:*',
        'query_cache:order_analytics:*',
        'query_cache:user_analytics:*',
        'query_cache:restaurant_analytics:*'
      ]
      
      cache_patterns.each do |pattern|
        Rails.cache.delete_matched(pattern) if Rails.cache.respond_to?(:delete_matched)
      end
      
      puts "✅ Cache clearing completed"
    end
  end

  desc "Show query cache statistics"
  task stats: :environment do
    puts "📊 Query Cache Statistics"
    puts "=" * 50
    
    stats = QueryCacheService.instance.cache_stats
    
    puts "Hit Rate: #{stats[:hit_rate]}%"
    puts "Total Requests: #{stats[:total_requests]}"
    puts "Cache Hits: #{stats[:cache_hits]}"
    puts "Cache Misses: #{stats[:cache_misses]}"
    puts "Errors: #{stats[:errors]}"
    puts "Average Query Time: #{stats[:average_query_time]}s"
    puts "Estimated Cache Size: #{stats[:cache_size_estimate]}"
    
    if stats[:total_requests] > 0
      puts "\n📈 Performance Impact:"
      puts "Cache Hit Ratio: #{(stats[:cache_hits].to_f / stats[:total_requests] * 100).round(2)}%"
      puts "Error Rate: #{(stats[:errors].to_f / stats[:total_requests] * 100).round(2)}%"
    end
  end

  desc "Warm specific cache type (metrics, analytics, orders, users)"
  task :warm_type, [:type] => :environment do |t, args|
    cache_type = args[:type]
    
    unless %w[metrics analytics orders users].include?(cache_type)
      puts "❌ Invalid cache type. Use: metrics, analytics, orders, or users"
      exit 1
    end
    
    puts "🔥 Warming #{cache_type} caches..."
    
    start_time = Time.current
    
    case cache_type
    when 'metrics'
      CacheWarmingService.warm_metrics
    when 'analytics'
      CacheWarmingService.warm_analytics
    when 'orders'
      CacheWarmingService.warm_orders
    when 'users'
      CacheWarmingService.instance.send(:warm_user_data)
    end
    
    execution_time = Time.current - start_time
    puts "✅ #{cache_type.capitalize} cache warming completed in #{execution_time.round(2)}s"
  end

  desc "Clear cache for specific user"
  task :clear_user, [:user_id] => :environment do |t, args|
    user_id = args[:user_id]
    
    unless user_id
      puts "❌ Please provide a user ID: rake query_cache:clear_user[123]"
      exit 1
    end
    
    puts "🧹 Clearing caches for user #{user_id}..."
    
    if Rails.cache.respond_to?(:delete_matched)
      Rails.cache.delete_matched("query_cache:*user_#{user_id}*")
      puts "✅ User #{user_id} caches cleared"
    else
      puts "⚠️  Cache backend doesn't support pattern deletion"
    end
  end

  desc "Clear cache for specific restaurant"
  task :clear_restaurant, [:restaurant_id] => :environment do |t, args|
    restaurant_id = args[:restaurant_id]
    
    unless restaurant_id
      puts "❌ Please provide a restaurant ID: rake query_cache:clear_restaurant[123]"
      exit 1
    end
    
    puts "🧹 Clearing caches for restaurant #{restaurant_id}..."
    
    if Rails.cache.respond_to?(:delete_matched)
      Rails.cache.delete_matched("query_cache:*restaurant_#{restaurant_id}*")
      puts "✅ Restaurant #{restaurant_id} caches cleared"
    else
      puts "⚠️  Cache backend doesn't support pattern deletion"
    end
  end

  desc "Monitor cache performance in real-time"
  task monitor: :environment do
    puts "📡 Monitoring query cache performance (Ctrl+C to stop)..."
    puts "=" * 60
    
    last_stats = QueryCacheService.instance.cache_stats
    
    loop do
      sleep 5
      
      current_stats = QueryCacheService.instance.cache_stats
      
      # Calculate deltas
      requests_delta = current_stats[:total_requests] - last_stats[:total_requests]
      hits_delta = current_stats[:cache_hits] - last_stats[:cache_hits]
      misses_delta = current_stats[:cache_misses] - last_stats[:cache_misses]
      
      if requests_delta > 0
        hit_rate = (hits_delta.to_f / requests_delta * 100).round(1)
        puts "[#{Time.current.strftime('%H:%M:%S')}] Requests: +#{requests_delta}, Hits: +#{hits_delta}, Misses: +#{misses_delta}, Hit Rate: #{hit_rate}%"
      else
        puts "[#{Time.current.strftime('%H:%M:%S')}] No new requests"
      end
      
      last_stats = current_stats
    end
  rescue Interrupt
    puts "\n👋 Monitoring stopped"
  end

  desc "Benchmark cache performance"
  task benchmark: :environment do
    puts "🏃 Benchmarking query cache performance..."
    puts "=" * 50
    
    require 'benchmark'
    
    # Test cache miss performance
    cache_key = "benchmark_test_#{Time.current.to_i}"
    
    miss_time = Benchmark.realtime do
      QueryCacheService.fetch(cache_key, cache_type: :metrics_summary) do
        # Simulate expensive query
        sleep(0.1)
        { data: "test_data", timestamp: Time.current }
      end
    end
    
    # Test cache hit performance
    hit_time = Benchmark.realtime do
      QueryCacheService.fetch(cache_key, cache_type: :metrics_summary) do
        # This shouldn't execute
        sleep(0.1)
        { data: "test_data", timestamp: Time.current }
      end
    end
    
    puts "Cache Miss Time: #{(miss_time * 1000).round(2)}ms"
    puts "Cache Hit Time: #{(hit_time * 1000).round(2)}ms"
    puts "Performance Improvement: #{(miss_time / hit_time).round(1)}x faster"
    
    # Clean up
    QueryCacheService.clear(cache_key, cache_type: :metrics_summary)
    
    puts "✅ Benchmark completed"
  end
end
