# frozen_string_literal: true

# Concern for adding query caching capabilities to controllers
module QueryCacheable
  extend ActiveSupport::Concern

  private

  # Cache expensive query results with automatic key generation
  # @param cache_type [Symbol] Type of cache (determines TTL)
  # @param key_parts [Array] Parts to build cache key
  # @param force_refresh [Boolean] Force cache refresh
  # @param &block [Block] Block to execute if cache miss
  # @return [Object] Cached or computed result
  def cache_query(cache_type:, key_parts: [], force_refresh: false, &)
    cache_key = build_controller_cache_key(key_parts)

    QueryCacheService.fetch(
      cache_key,
      cache_type: cache_type,
      force_refresh: force_refresh,
      &
    )
  end

  # Cache metrics data with user-specific scoping
  # @param metric_name [String] Name of the metric
  # @param user_scope [Boolean] Include user ID in cache key
  # @param restaurant_scope [Boolean] Include restaurant ID in cache key
  # @param force_refresh [Boolean] Force cache refresh
  # @param &block [Block] Block to execute if cache miss
  # @return [Object] Cached or computed result
  def cache_metrics(metric_name, user_scope: true, restaurant_scope: false, force_refresh: false, &)
    key_parts = [metric_name]
    key_parts << "user_#{current_user.id}" if user_scope && current_user
    key_parts << "restaurant_#{params[:restaurant_id]}" if restaurant_scope && params[:restaurant_id]

    cache_query(
      cache_type: :metrics_summary,
      key_parts: key_parts,
      force_refresh: force_refresh,
      &
    )
  end

  # Cache analytics data with time-based scoping
  # @param analytics_type [String] Type of analytics
  # @param time_range [String] Time range identifier (e.g., 'daily', 'weekly')
  # @param additional_params [Hash] Additional parameters for cache key
  # @param force_refresh [Boolean] Force cache refresh
  # @param &block [Block] Block to execute if cache miss
  # @return [Object] Cached or computed result
  def cache_analytics(analytics_type, time_range: 'daily', additional_params: {}, force_refresh: false, &)
    key_parts = [analytics_type, time_range]
    key_parts << "user_#{current_user.id}" if current_user

    # Add additional parameters to cache key
    additional_params.each do |key, value|
      key_parts << "#{key}_#{value}" if value.present?
    end

    cache_type = case time_range
                 when 'hourly', 'recent'
                   :recent_metrics
                 when 'daily'
                   :daily_stats
                 when 'weekly', 'monthly'
                   :monthly_reports
                 else
                   :analytics_dashboard
                 end

    cache_query(
      cache_type: cache_type,
      key_parts: key_parts,
      force_refresh: force_refresh,
      &
    )
  end

  # Cache order analytics with restaurant scoping
  # @param report_type [String] Type of order report
  # @param restaurant_id [Integer] Restaurant ID for scoping
  # @param date_range [Hash] Date range parameters
  # @param force_refresh [Boolean] Force cache refresh
  # @param &block [Block] Block to execute if cache miss
  # @return [Object] Cached or computed result
  def cache_order_analytics(report_type, restaurant_id: nil, date_range: {}, force_refresh: false, &)
    key_parts = [report_type]
    key_parts << "restaurant_#{restaurant_id}" if restaurant_id
    key_parts << "user_#{current_user.id}" if current_user

    # Add date range to cache key
    if date_range.present?
      date_key = "#{date_range[:start]}_to_#{date_range[:end]}"
      key_parts << date_key
    end

    cache_query(
      cache_type: :order_analytics,
      key_parts: key_parts,
      force_refresh: force_refresh,
      &
    )
  end

  # Clear cache for current controller/action
  # @param key_parts [Array] Specific key parts to clear
  def clear_controller_cache(key_parts = [])
    cache_key = build_controller_cache_key(key_parts)
    QueryCacheService.clear(cache_key)
  end

  # Clear all cache entries for current user
  def clear_user_cache
    if current_user
      QueryCacheService.clear_pattern("*user_#{current_user.id}*")
    end
  end

  # Clear all cache entries for a specific restaurant
  # @param restaurant_id [Integer] Restaurant ID
  def clear_restaurant_cache(restaurant_id)
    QueryCacheService.clear_pattern("*restaurant_#{restaurant_id}*")
  end

  # Force refresh cache for current request
  def force_cache_refresh?
    params[:force_refresh] == 'true' || params[:refresh_cache] == 'true'
  end

  # Build cache key specific to current controller and action
  # @param key_parts [Array] Additional key parts
  # @return [String] Cache key
  def build_controller_cache_key(key_parts = [])
    base_parts = [controller_name, action_name]
    base_parts.concat(key_parts)
    base_parts.compact.join(':')
  end

  # Add cache headers to response for debugging
  # @param cache_hit [Boolean] Whether this was a cache hit
  # @param cache_key [String] Cache key used
  def add_cache_headers(cache_hit: false, cache_key: nil)
    response.headers['X-Cache-Status'] = cache_hit ? 'HIT' : 'MISS'
    response.headers['X-Cache-Key'] = cache_key if cache_key
    response.headers['X-Cache-Timestamp'] = Time.current.iso8601
  end

  # Get cache statistics for current user/controller
  # @return [Hash] Cache statistics
  def cache_statistics
    QueryCacheService.instance.cache_stats
  end
end
