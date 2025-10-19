# frozen_string_literal: true

# L2 (Level 2) Query Cache Service
# Provides intelligent caching for complex database queries with automatic invalidation
class L2QueryCacheService
  include Singleton

  # Cache TTL configurations for different query types
  QUERY_CACHE_DURATIONS = {
    complex_join: 10.minutes,
    aggregate: 15.minutes,
    dashboard: 10.minutes,
    analytics: 20.minutes,
    report: 1.hour,
    default: 5.minutes,
  }.freeze

  class << self
    delegate :fetch_query, :clear_query_cache, :clear_pattern, :cache_stats, to: :instance
  end

  # Fetch cached query result or execute and cache
  # @param sql [String] SQL query string
  # @param bindings [Array] Query parameter bindings
  # @param cache_type [Symbol] Type of cache (determines TTL)
  # @param force_refresh [Boolean] Force cache refresh
  # @return [ActiveRecord::Result] Query result
  def fetch_query(sql, bindings = [], cache_type: :default, force_refresh: false)
    cache_key = generate_query_fingerprint(sql, bindings)
    ttl = QUERY_CACHE_DURATIONS[cache_type] || QUERY_CACHE_DURATIONS[:default]

    if force_refresh
      Rails.cache.delete(cache_key)
    end

    start_time = Time.current
    
    result = Rails.cache.fetch(cache_key, expires_in: ttl) do
      Rails.logger.info "[L2QueryCache] Cache miss for query, executing..."
      
      query_start = Time.current
      raw_result = execute_query(sql, bindings)
      query_time = Time.current - query_start
      
      Rails.logger.info "[L2QueryCache] Query executed in #{query_time.round(3)}s, caching for #{ttl}"
      
      # Track performance
      track_query_performance(cache_key, query_time, :miss)
      
      serialize_query_result(raw_result)
    end

    total_time = Time.current - start_time
    
    # Track cache hit
    if total_time < 0.01 # Less than 10ms indicates cache hit
      track_query_performance(cache_key, total_time, :hit)
    end

    deserialize_query_result(result)
  rescue StandardError => e
    Rails.logger.error "[L2QueryCache] Error executing query: #{e.message}"
    track_query_performance(cache_key, 0, :error)
    raise
  end

  # Clear specific query cache
  # @param sql [String] SQL query string
  # @param bindings [Array] Query parameter bindings
  def clear_query_cache(sql, bindings = [])
    cache_key = generate_query_fingerprint(sql, bindings)
    Rails.cache.delete(cache_key)
    Rails.logger.info "[L2QueryCache] Cleared cache for query"
  end

  # Clear all cache entries matching a pattern
  # @param pattern [String] Pattern to match
  def clear_pattern(pattern)
    if Rails.cache.respond_to?(:delete_matched)
      full_pattern = "l2_query:#{pattern}"
      Rails.cache.delete_matched(full_pattern)
      Rails.logger.info "[L2QueryCache] Cleared cache pattern: #{pattern}"
    else
      Rails.logger.warn "[L2QueryCache] Cache backend doesn't support pattern deletion"
    end
  end

  # Get cache statistics
  # @return [Hash] Cache performance statistics
  def cache_stats
    performance_data = query_performance_data
    
    {
      total_queries: performance_data[:total_queries],
      cache_hits: performance_data[:cache_hits],
      cache_misses: performance_data[:cache_misses],
      errors: performance_data[:errors],
      hit_rate: calculate_hit_rate(performance_data),
      average_cached_time: calculate_average_time(performance_data, :cached),
      average_uncached_time: calculate_average_time(performance_data, :uncached),
      performance_improvement: calculate_performance_improvement(performance_data),
    }
  end

  private

  # Generate unique fingerprint for query
  # @param sql [String] SQL query string
  # @param bindings [Array] Query parameter bindings
  # @return [String] Cache key
  def generate_query_fingerprint(sql, bindings)
    normalized_sql = normalize_sql(sql)
    sql_hash = Digest::SHA256.hexdigest(normalized_sql)
    binding_hash = Digest::SHA256.hexdigest(bindings.to_json)
    
    "l2_query:#{sql_hash}:#{binding_hash}"
  end

  # Normalize SQL query for consistent caching
  # @param sql [String] SQL query string
  # @return [String] Normalized SQL
  def normalize_sql(sql)
    # Remove extra whitespace, lowercase, remove comments
    sql.gsub(/\s+/, ' ')
       .gsub(/--.*$/, '')
       .gsub(/\/\*.*?\*\//m, '')
       .strip
       .downcase
  end

  # Execute SQL query
  # @param sql [String] SQL query string
  # @param bindings [Array] Query parameter bindings
  # @return [ActiveRecord::Result] Query result
  def execute_query(sql, bindings)
    # Always execute without bindings since SQL is already parameterized
    ActiveRecord::Base.connection.exec_query(sql)
  end

  # Serialize query result for caching
  # @param result [ActiveRecord::Result] Query result
  # @return [Hash] Serialized result
  def serialize_query_result(result)
    {
      columns: result.columns,
      rows: result.rows,
      column_types: result.column_types.transform_values(&:type),
    }
  end

  # Deserialize cached query result
  # @param data [Hash] Serialized result
  # @return [ActiveRecord::Result] Query result
  def deserialize_query_result(data)
    # Reconstruct column types
    column_types = data[:column_types].transform_values do |type|
      ActiveRecord::Type.lookup(type)
    end
    
    ActiveRecord::Result.new(
      data[:columns],
      data[:rows],
      column_types
    )
  end

  # Track query performance metrics
  # @param cache_key [String] Cache key
  # @param execution_time [Float] Query execution time
  # @param result_type [Symbol] :hit, :miss, or :error
  def track_query_performance(cache_key, execution_time, result_type)
    performance_data = query_performance_data
    
    performance_data[:total_queries] += 1
    performance_data[:"cache_#{result_type}s"] += 1
    
    if result_type == :hit
      performance_data[:total_cached_time] += execution_time
    elsif result_type == :miss
      performance_data[:total_uncached_time] += execution_time
    end
    
    # Store updated performance data
    Rails.cache.write('l2_query_cache:performance', performance_data, expires_in: 1.hour)
  rescue StandardError => e
    Rails.logger.error "[L2QueryCache] Error tracking performance: #{e.message}"
  end

  # Get query performance data from cache
  # @return [Hash] Performance data
  def query_performance_data
    Rails.cache.fetch('l2_query_cache:performance', expires_in: 1.hour) do
      {
        total_queries: 0,
        cache_hits: 0,
        cache_misses: 0,
        errors: 0,
        total_cached_time: 0.0,
        total_uncached_time: 0.0,
      }
    end
  end

  # Calculate cache hit rate
  # @param data [Hash] Performance data
  # @return [Float] Hit rate percentage
  def calculate_hit_rate(data)
    total = data[:cache_hits] + data[:cache_misses]
    return 0.0 if total.zero?

    (data[:cache_hits].to_f / total * 100).round(2)
  end

  # Calculate average query time
  # @param data [Hash] Performance data
  # @param type [Symbol] :cached or :uncached
  # @return [Float] Average time in milliseconds
  def calculate_average_time(data, type)
    if type == :cached
      count = data[:cache_hits]
      total_time = data[:total_cached_time]
    else
      count = data[:cache_misses]
      total_time = data[:total_uncached_time]
    end
    
    return 0.0 if count.zero?
    
    (total_time / count * 1000).round(2) # Convert to milliseconds
  end

  # Calculate performance improvement percentage
  # @param data [Hash] Performance data
  # @return [Float] Improvement percentage
  def calculate_performance_improvement(data)
    cached_avg = calculate_average_time(data, :cached)
    uncached_avg = calculate_average_time(data, :uncached)
    
    return 0.0 if uncached_avg.zero?
    
    improvement = ((uncached_avg - cached_avg) / uncached_avg * 100).round(2)
    [improvement, 0.0].max # Don't show negative improvements
  end
end
