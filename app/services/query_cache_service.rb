# frozen_string_literal: true

# Service for managing complex query result caching
# Provides intelligent caching strategies for expensive database operations
class QueryCacheService
  include Singleton

  # Cache TTL configurations for different types of queries
  CACHE_DURATIONS = {
    metrics_summary: 5.minutes,
    system_metrics: 1.minute,
    recent_metrics: 30.seconds,
    analytics_dashboard: 10.minutes,
    order_analytics: 15.minutes,
    revenue_reports: 1.hour,
    daily_stats: 6.hours,
    monthly_reports: 24.hours,
    user_analytics: 30.minutes,
    restaurant_analytics: 20.minutes,
  }.freeze

  class << self
    delegate :fetch, :clear, :clear_pattern, :clear_performance_data, :warm_cache, to: :instance
  end

  # Fetch cached result or execute block and cache the result
  # @param cache_key [String] Unique cache key
  # @param cache_type [Symbol] Type of cache (determines TTL)
  # @param force_refresh [Boolean] Force cache refresh
  # @param &block [Block] Block to execute if cache miss
  # @return [Object] Cached or computed result
  def fetch(cache_key, cache_type: :default, force_refresh: false)
    full_key = build_cache_key(cache_key, cache_type)
    ttl = CACHE_DURATIONS[cache_type] || 5.minutes

    if force_refresh
      Rails.cache.delete(full_key)
    end

    Rails.cache.fetch(full_key, expires_in: ttl) do
      Rails.logger.info "[QueryCache] Cache miss for #{full_key}, executing query"

      start_time = Time.current
      result = yield
      execution_time = Time.current - start_time

      Rails.logger.info "[QueryCache] Query executed in #{execution_time.round(3)}s, cached for #{ttl}"

      # Track cache performance
      track_cache_performance(cache_type, execution_time, :miss)

      result
    end
  rescue StandardError => e
    Rails.logger.error "[QueryCache] Error executing query for #{full_key}: #{e.message}"
    track_cache_performance(cache_type, 0, :error)
    raise
  end

  # Clear specific cache entry
  # @param cache_key [String] Cache key to clear
  # @param cache_type [Symbol] Type of cache
  def clear(cache_key, cache_type: :default)
    full_key = build_cache_key(cache_key, cache_type)
    Rails.cache.delete(full_key)
    Rails.logger.info "[QueryCache] Cleared cache for #{full_key}"
  end

  # Clear all cache entries matching a pattern
  # @param pattern [String] Pattern to match (supports wildcards)
  def clear_pattern(pattern)
    if Rails.cache.respond_to?(:delete_matched)
      Rails.cache.delete_matched("query_cache:#{pattern}")
      Rails.logger.info "[QueryCache] Cleared cache pattern: #{pattern}"
    else
      Rails.logger.warn "[QueryCache] Cache backend doesn't support pattern deletion"
    end
  end

  # Clear performance data cache (useful for fixing corruption)
  def clear_performance_data
    Rails.cache.delete('query_cache:performance')
    Rails.logger.info "[QueryCache] Cleared performance data cache"
  end

  # Pre-warm cache with commonly accessed data
  # @param cache_configs [Array<Hash>] Array of cache configurations
  def warm_cache(cache_configs = [])
    Rails.logger.info "[QueryCache] Starting cache warming for #{cache_configs.size} entries"

    cache_configs.each do |config|
      fetch(config[:key], cache_type: config[:type], &config[:block])
    rescue StandardError => e
      Rails.logger.error "[QueryCache] Failed to warm cache for #{config[:key]}: #{e.message}"
    end

    Rails.logger.info '[QueryCache] Cache warming completed'
  end

  # Get cache statistics
  # @return [Hash] Cache performance statistics
  def cache_stats
    {
      hit_rate: calculate_hit_rate,
      total_requests: cache_performance_data[:total_requests],
      cache_hits: cache_performance_data[:cache_hits],
      cache_misses: cache_performance_data[:cache_misses],
      errors: cache_performance_data[:errors],
      average_query_time: calculate_average_query_time,
      cache_size_estimate: estimate_cache_size,
    }
  end

  private

  # Build full cache key with namespace and type
  # @param cache_key [String] Base cache key
  # @param cache_type [Symbol] Cache type
  # @return [String] Full cache key
  def build_cache_key(cache_key, cache_type)
    "query_cache:#{cache_type}:#{cache_key}"
  end

  # Track cache performance metrics
  # @param cache_type [Symbol] Type of cache
  # @param execution_time [Float] Query execution time
  # @param result_type [Symbol] :hit, :miss, or :error
  def track_cache_performance(cache_type, execution_time, result_type)
    return unless Rails.env.production? || Rails.env.development?
    
    begin
      performance_data = cache_performance_data
      
      # Ensure all values are not nil before performing arithmetic
      performance_data[:total_requests] = (performance_data[:total_requests] || 0) + 1
      performance_data[:"cache_#{result_type}s"] = (performance_data[:"cache_#{result_type}s"] || 0) + 1
      performance_data[:total_query_time] = (performance_data[:total_query_time] || 0.0) + (execution_time || 0.0)
      
      performance_data[:by_type][cache_type] ||= { requests: 0, total_time: 0.0 }
      performance_data[:by_type][cache_type][:requests] = (performance_data[:by_type][cache_type][:requests] || 0) + 1
      performance_data[:by_type][cache_type][:total_time] = (performance_data[:by_type][cache_type][:total_time] || 0.0) + (execution_time || 0.0)

      # Store updated performance data
      Rails.cache.write('query_cache:performance', performance_data, expires_in: 1.hour)
    rescue StandardError => e
      Rails.logger.warn "[QueryCache] Failed to track performance: #{e.message}"
    end
  end

  # Get cache performance data from cache
  # @return [Hash] Performance data
  def cache_performance_data
    # Don't use instance variable to avoid corruption between requests
    data = Rails.cache.fetch('query_cache:performance', expires_in: 1.hour) do
      {
        total_requests: 0,
        cache_hits: 0,
        cache_misses: 0,
        errors: 0,
        total_query_time: 0.0,
        by_type: {},
      }
    end
    
    # Ensure data integrity - return default if data is corrupted
    return default_performance_data unless data.is_a?(Hash)
    
    # Ensure all required keys exist with proper defaults
    {
      total_requests: data[:total_requests] || 0,
      cache_hits: data[:cache_hits] || 0,
      cache_misses: data[:cache_misses] || 0,
      errors: data[:errors] || 0,
      total_query_time: data[:total_query_time] || 0.0,
      by_type: data[:by_type] || {},
    }
  end
  
  # Default performance data structure
  def default_performance_data
    {
      total_requests: 0,
      cache_hits: 0,
      cache_misses: 0,
      errors: 0,
      total_query_time: 0.0,
      by_type: {},
    }
  end

  # Calculate cache hit rate
  # @return [Float] Hit rate percentage
  def calculate_hit_rate
    begin
      data = cache_performance_data
      hits = data[:cache_hits] || 0
      misses = data[:cache_misses] || 0
      total = hits + misses
      return 0.0 if total.zero?

      (hits.to_f / total * 100).round(2)
    rescue StandardError => e
      Rails.logger.warn "[QueryCache] Error calculating hit rate: #{e.message}"
      0.0
    end
  end

  # Calculate average query execution time
  # @return [Float] Average time in seconds
  def calculate_average_query_time
    begin
      data = cache_performance_data
      misses = data[:cache_misses] || 0
      total_time = data[:total_query_time] || 0.0
      return 0.0 if misses.zero?

      (total_time / misses).round(4)
    rescue StandardError => e
      Rails.logger.warn "[QueryCache] Error calculating average query time: #{e.message}"
      0.0
    end
  end

  # Estimate cache size (rough approximation)
  # @return [String] Human readable cache size estimate
  def estimate_cache_size
    # This is a rough estimate - actual implementation would depend on cache backend
    "~#{cache_performance_data[:total_requests] * 2}KB"
  end
end
