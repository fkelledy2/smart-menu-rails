# frozen_string_literal: true

# BrowserCacheAnalyticsService
#
# Tracks and analyzes browser cache performance metrics.
# Monitors cache hit rates, ETag validation, and cache effectiveness.
#
# Usage:
#   BrowserCacheAnalyticsService.track_request(request, response)
#   BrowserCacheAnalyticsService.performance_summary
#   BrowserCacheAnalyticsService.cache_health
#
class BrowserCacheAnalyticsService
  include Singleton

  class << self
    delegate :track_request, :track_etag_validation, :performance_summary, 
             :cache_health, :reset_stats, to: :instance
  end

  # Track a request for analytics
  # @param request [ActionDispatch::Request] The request object
  # @param response [ActionDispatch::Response] The response object
  def track_request(request, response)
    return if request.nil? || response.nil?

    stats = get_stats
    
    stats[:total_requests] += 1
    stats[:requests_by_status][response.status] ||= 0
    stats[:requests_by_status][response.status] += 1

    # Track cache headers
    cache_control = response.headers['Cache-Control']
    if cache_control
      track_cache_control(stats, cache_control)
    end

    # Track ETag usage
    if response.headers['ETag']
      stats[:etag_responses] += 1
    end

    # Track 304 Not Modified responses
    if response.status == 304
      stats[:not_modified_responses] += 1
    end

    # Track content type
    content_type = response.content_type&.split(';')&.first || 'unknown'
    stats[:by_content_type][content_type] ||= 0
    stats[:by_content_type][content_type] += 1

    save_stats(stats)
  rescue StandardError => e
    Rails.logger.error "[Browser Cache Analytics] Error tracking request: #{e.message}"
  end

  # Track ETag validation
  # @param matched [Boolean] Whether ETag matched
  def track_etag_validation(matched)
    return if matched.nil?

    stats = get_stats
    
    if matched
      stats[:etag_matches] += 1
    else
      stats[:etag_mismatches] += 1
    end

    save_stats(stats)
  rescue StandardError => e
    Rails.logger.error "[Browser Cache Analytics] Error tracking ETag: #{e.message}"
  end

  # Get performance summary
  # @return [Hash] Performance metrics
  def performance_summary
    stats = get_stats
    
    {
      total_requests: stats[:total_requests],
      cached_responses: stats[:cached_responses],
      no_cache_responses: stats[:no_cache_responses],
      not_modified_responses: stats[:not_modified_responses],
      etag_responses: stats[:etag_responses],
      cache_hit_rate: calculate_cache_hit_rate(stats),
      etag_validation_rate: calculate_etag_validation_rate(stats),
      not_modified_rate: calculate_not_modified_rate(stats),
      by_content_type: stats[:by_content_type],
      by_status: stats[:requests_by_status]
    }
  end

  # Get cache health status
  # @return [Hash] Health status
  def cache_health
    stats = get_stats
    summary = performance_summary

    health_status = determine_health_status(summary)
    
    {
      status: health_status,
      cache_hit_rate: summary[:cache_hit_rate],
      etag_validation_rate: summary[:etag_validation_rate],
      not_modified_rate: summary[:not_modified_rate],
      total_requests: summary[:total_requests],
      recommendations: generate_recommendations(summary)
    }
  end

  # Reset statistics
  def reset_stats
    Rails.cache.delete('browser_cache_analytics:stats')
    Rails.logger.info '[Browser Cache Analytics] Statistics reset'
  end

  private

  # Get current statistics
  def get_stats
    Rails.cache.read('browser_cache_analytics:stats') || default_stats
  end

  # Save statistics
  def save_stats(stats)
    Rails.cache.write('browser_cache_analytics:stats', stats, expires_in: 24.hours)
  end

  # Default statistics structure
  def default_stats
    {
      total_requests: 0,
      cached_responses: 0,
      no_cache_responses: 0,
      not_modified_responses: 0,
      etag_responses: 0,
      etag_matches: 0,
      etag_mismatches: 0,
      by_content_type: {},
      requests_by_status: {},
      cache_control_directives: {}
    }
  end

  # Track cache control directives
  def track_cache_control(stats, cache_control)
    if cache_control.include?('no-cache') || cache_control.include?('no-store')
      stats[:no_cache_responses] += 1
    else
      stats[:cached_responses] += 1
    end

    # Track specific directives
    directives = cache_control.split(',').map(&:strip)
    directives.each do |directive|
      stats[:cache_control_directives][directive] ||= 0
      stats[:cache_control_directives][directive] += 1
    end
  end

  # Calculate cache hit rate
  def calculate_cache_hit_rate(stats)
    total = stats[:total_requests]
    return 0.0 if total.zero?

    cached = stats[:cached_responses]
    ((cached.to_f / total) * 100).round(2)
  end

  # Calculate ETag validation rate
  def calculate_etag_validation_rate(stats)
    total = stats[:etag_responses]
    return 0.0 if total.zero?

    matches = stats[:etag_matches]
    ((matches.to_f / total) * 100).round(2)
  end

  # Calculate 304 Not Modified rate
  def calculate_not_modified_rate(stats)
    total = stats[:total_requests]
    return 0.0 if total.zero?

    not_modified = stats[:not_modified_responses]
    ((not_modified.to_f / total) * 100).round(2)
  end

  # Determine health status
  def determine_health_status(summary)
    cache_hit_rate = summary[:cache_hit_rate]
    not_modified_rate = summary[:not_modified_rate]

    if cache_hit_rate >= 85 && not_modified_rate >= 35
      'excellent'
    elsif cache_hit_rate >= 60 && not_modified_rate >= 25
      'good'
    elsif cache_hit_rate >= 40 && not_modified_rate >= 15
      'fair'
    else
      'poor'
    end
  end

  # Generate recommendations
  def generate_recommendations(summary)
    recommendations = []

    if summary[:cache_hit_rate] < 60
      recommendations << 'Consider increasing cache TTLs for static content'
    end

    if summary[:etag_validation_rate] < 50
      recommendations << 'Implement ETags for more endpoints to improve conditional requests'
    end

    if summary[:not_modified_rate] < 30
      recommendations << 'Enable ETag validation in more controllers'
    end

    no_cache_ratio = summary[:no_cache_responses].to_f / summary[:total_requests]
    if no_cache_ratio > 0.5
      recommendations << 'Too many no-cache responses - review caching strategy'
    end

    recommendations << 'Browser cache is performing well' if recommendations.empty?

    recommendations
  end
end
