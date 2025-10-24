# frozen_string_literal: true

# Service for tracking and analyzing performance by geographic region
# Monitors latency, identifies slow regions, and provides optimization recommendations
class RegionalPerformanceService
  include Singleton

  class << self
    delegate :track_latency, :metrics_for_region, :slowest_regions, :all_regions_summary, to: :instance
  end

  # Track request latency for a specific region
  # @param request [ActionDispatch::Request] Request object
  # @param duration [Float] Request duration in milliseconds
  # @return [Boolean] Success status
  def track_latency(request, duration)
    location = GeoRoutingService.detect_location(request)
    region = location[:region]

    Rails.logger.debug "[RegionalPerformance] Tracking latency for #{region}: #{duration}ms"

    # Store metric in cache for aggregation
    cache_key = "regional_performance:#{region}:#{Date.current}"
    metrics = Rails.cache.fetch(cache_key, expires_in: 25.hours) { [] }
    
    metrics << {
      duration: duration,
      timestamp: Time.current.to_i,
      path: request.path,
      method: request.method
    }

    # Keep only last 1000 requests per region per day
    metrics = metrics.last(1000)
    
    Rails.cache.write(cache_key, metrics, expires_in: 25.hours)

    # Alert if threshold exceeded
    alert_if_slow(region, duration)

    true
  rescue StandardError => e
    Rails.logger.error "[RegionalPerformance] Failed to track latency: #{e.message}"
    false
  end

  # Get performance metrics for a specific region
  # @param region [String] Region code
  # @param period [String] Time period ('24h', '7d', '30d')
  # @return [Hash] Performance metrics
  def metrics_for_region(region, period: '24h')
    days = period_to_days(period)
    all_metrics = []

    days.times do |i|
      date = Date.current - i.days
      cache_key = "regional_performance:#{region}:#{date}"
      metrics = Rails.cache.read(cache_key) || []
      all_metrics.concat(metrics)
    end

    return empty_metrics if all_metrics.empty?

    calculate_metrics(all_metrics, region)
  end

  # Get slowest regions with their metrics
  # @param limit [Integer] Number of regions to return
  # @param period [String] Time period
  # @return [Array<Hash>] Regions sorted by p95 latency
  def slowest_regions(limit: 5, period: '24h')
    regions = GeoRoutingService.supported_regions
    
    region_metrics = regions.map do |region|
      metrics = metrics_for_region(region, period: period)
      metrics.merge(region: region)
    end

    # Sort by p95 latency (descending)
    region_metrics.sort_by { |m| -m[:p95] }.first(limit)
  end

  # Get summary of all regions
  # @param period [String] Time period
  # @return [Hash] Summary by region
  def all_regions_summary(period: '24h')
    regions = GeoRoutingService.supported_regions
    
    summary = {}
    regions.each do |region|
      summary[region] = metrics_for_region(region, period: period)
    end

    summary
  end

  # Check if region is performing poorly
  # @param region [String] Region code
  # @param threshold_ms [Integer] Threshold in milliseconds
  # @return [Boolean] True if region is slow
  def region_slow?(region, threshold_ms: 500)
    metrics = metrics_for_region(region, period: '24h')
    metrics[:p95] > threshold_ms
  end

  # Get recommendations for slow regions
  # @param region [String] Region code
  # @return [Array<String>] Optimization recommendations
  def recommendations_for_region(region)
    metrics = metrics_for_region(region, period: '24h')
    recommendations = []

    if metrics[:p95] > 1000
      recommendations << "Critical: p95 latency exceeds 1s - consider adding edge location in #{region}"
    elsif metrics[:p95] > 500
      recommendations << "Warning: p95 latency exceeds 500ms - optimize cache warming for #{region}"
    end

    if metrics[:avg] > 300
      recommendations << "Average latency high - review database query performance"
    end

    if metrics[:request_count] < 10
      recommendations << "Low traffic - insufficient data for accurate analysis"
    end

    recommendations << "Performance acceptable" if recommendations.empty?
    recommendations
  end

  private

  # Convert period string to number of days
  # @param period [String] Period string
  # @return [Integer] Number of days
  def period_to_days(period)
    case period
    when '24h' then 1
    when '7d' then 7
    when '30d' then 30
    else 1
    end
  end

  # Calculate performance metrics from raw data
  # @param metrics [Array<Hash>] Raw metrics
  # @param region [String] Region code
  # @return [Hash] Calculated metrics
  def calculate_metrics(metrics, region)
    durations = metrics.map { |m| m[:duration] }.sort

    {
      region: region,
      request_count: metrics.size,
      avg: calculate_average(durations),
      median: calculate_percentile(durations, 50),
      p50: calculate_percentile(durations, 50),
      p95: calculate_percentile(durations, 95),
      p99: calculate_percentile(durations, 99),
      min: durations.first || 0,
      max: durations.last || 0,
      period: '24h'
    }
  end

  # Calculate average
  # @param values [Array<Numeric>] Values
  # @return [Float] Average
  def calculate_average(values)
    return 0.0 if values.empty?
    
    values.sum.to_f / values.size
  end

  # Calculate percentile
  # @param values [Array<Numeric>] Sorted values
  # @param percentile [Integer] Percentile (0-100)
  # @return [Float] Percentile value
  def calculate_percentile(values, percentile)
    return 0.0 if values.empty?
    
    index = ((percentile / 100.0) * values.size).ceil - 1
    index = [0, [index, values.size - 1].min].max
    
    values[index] || 0.0
  end

  # Return empty metrics structure
  # @return [Hash] Empty metrics
  def empty_metrics
    {
      request_count: 0,
      avg: 0.0,
      median: 0.0,
      p50: 0.0,
      p95: 0.0,
      p99: 0.0,
      min: 0.0,
      max: 0.0,
      period: '24h'
    }
  end

  # Alert if latency exceeds threshold
  # @param region [String] Region code
  # @param duration [Float] Duration in milliseconds
  # @return [void]
  def alert_if_slow(region, duration)
    threshold = ENV.fetch('REGIONAL_LATENCY_THRESHOLD', 1000).to_i
    
    return unless duration > threshold

    Rails.logger.warn "[RegionalPerformance] High latency detected in #{region}: #{duration}ms (threshold: #{threshold}ms)"
    
    # In production, this would trigger an alert (PagerDuty, Slack, etc.)
  end
end
