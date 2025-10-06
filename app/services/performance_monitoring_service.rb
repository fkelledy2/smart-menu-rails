# frozen_string_literal: true

class PerformanceMonitoringService
  include Singleton

  # Performance thresholds (in milliseconds)
  SLOW_QUERY_THRESHOLD = 100
  SLOW_REQUEST_THRESHOLD = 500
  MEMORY_WARNING_THRESHOLD = 100 # MB

  class << self
    delegate :track_request, :track_query, :track_cache_hit, :track_cache_miss,
             :get_metrics, :get_slow_queries, :get_request_stats, :reset_metrics,
             to: :instance
  end

  def initialize
    @metrics = {
      requests: [],
      queries: [],
      cache_hits: 0,
      cache_misses: 0,
      memory_usage: [],
      started_at: Time.current
    }
    @mutex = Mutex.new
  end

  # Track HTTP request performance
  def track_request(controller:, action:, duration:, status:, method: 'GET', path: nil)
    @mutex.synchronize do
      @metrics[:requests] << {
        controller: controller,
        action: action,
        duration: duration.round(2),
        status: status,
        method: method,
        path: path,
        timestamp: Time.current,
        slow: duration > SLOW_REQUEST_THRESHOLD
      }

      # Keep only last 1000 requests to prevent memory bloat
      @metrics[:requests] = @metrics[:requests].last(1000)
    end

    # Log slow requests
    if duration > SLOW_REQUEST_THRESHOLD
      Rails.logger.warn "[PERFORMANCE] Slow request: #{controller}##{action} took #{duration}ms"
    end
  end

  # Track database query performance
  def track_query(sql:, duration:, name: nil)
    @mutex.synchronize do
      @metrics[:queries] << {
        sql: sql.truncate(200),
        duration: duration.round(2),
        name: name,
        timestamp: Time.current,
        slow: duration > SLOW_QUERY_THRESHOLD
      }

      # Keep only last 500 queries
      @metrics[:queries] = @metrics[:queries].last(500)
    end

    # Log slow queries
    if duration > SLOW_QUERY_THRESHOLD
      Rails.logger.warn "[PERFORMANCE] Slow query: #{name || 'Unknown'} took #{duration}ms - #{sql.truncate(100)}"
    end
  end

  # Track cache performance
  def track_cache_hit
    @mutex.synchronize { @metrics[:cache_hits] += 1 }
  end

  def track_cache_miss
    @mutex.synchronize { @metrics[:cache_misses] += 1 }
  end

  # Track memory usage
  def track_memory_usage
    return unless defined?(GC)

    memory_mb = (GC.stat[:heap_allocated_pages] * GC::INTERNAL_CONSTANTS[:HEAP_PAGE_SIZE]) / (1024 * 1024)
    
    @mutex.synchronize do
      @metrics[:memory_usage] << {
        memory_mb: memory_mb.round(2),
        timestamp: Time.current
      }

      # Keep only last 100 memory samples
      @metrics[:memory_usage] = @metrics[:memory_usage].last(100)
    end

    # Log memory warnings
    if memory_mb > MEMORY_WARNING_THRESHOLD
      Rails.logger.warn "[PERFORMANCE] High memory usage: #{memory_mb}MB"
    end
  end

  # Get comprehensive metrics
  def get_metrics
    @mutex.synchronize do
      {
        summary: calculate_summary,
        requests: @metrics[:requests].last(50), # Last 50 requests
        slow_requests: @metrics[:requests].select { |r| r[:slow] }.last(20),
        queries: @metrics[:queries].last(50), # Last 50 queries
        slow_queries: @metrics[:queries].select { |q| q[:slow] }.last(20),
        cache_stats: {
          hits: @metrics[:cache_hits],
          misses: @metrics[:cache_misses],
          hit_rate: cache_hit_rate
        },
        memory_usage: @metrics[:memory_usage].last(20),
        uptime: Time.current - @metrics[:started_at]
      }
    end
  end

  # Get slow queries for optimization
  def get_slow_queries(limit: 20)
    @mutex.synchronize do
      @metrics[:queries]
        .select { |q| q[:slow] }
        .group_by { |q| q[:name] || q[:sql] }
        .map do |query, instances|
          {
            query: query,
            count: instances.size,
            avg_duration: (instances.sum { |i| i[:duration] } / instances.size).round(2),
            max_duration: instances.map { |i| i[:duration] }.max,
            last_seen: instances.map { |i| i[:timestamp] }.max
          }
        end
        .sort_by { |q| -q[:avg_duration] }
        .first(limit)
    end
  end

  # Get request performance stats
  def get_request_stats
    @mutex.synchronize do
      return {} if @metrics[:requests].empty?

      durations = @metrics[:requests].map { |r| r[:duration] }
      
      {
        total_requests: @metrics[:requests].size,
        avg_response_time: (durations.sum / durations.size).round(2),
        median_response_time: calculate_median(durations),
        p95_response_time: calculate_percentile(durations, 95),
        p99_response_time: calculate_percentile(durations, 99),
        slow_requests_count: @metrics[:requests].count { |r| r[:slow] },
        slow_requests_percentage: ((@metrics[:requests].count { |r| r[:slow] }.to_f / @metrics[:requests].size) * 100).round(2)
      }
    end
  end

  # Reset all metrics
  def reset_metrics
    @mutex.synchronize do
      @metrics = {
        requests: [],
        queries: [],
        cache_hits: 0,
        cache_misses: 0,
        memory_usage: [],
        started_at: Time.current
      }
    end
  end

  private

  def calculate_summary
    {
      total_requests: @metrics[:requests].size,
      total_queries: @metrics[:queries].size,
      slow_requests: @metrics[:requests].count { |r| r[:slow] },
      slow_queries: @metrics[:queries].count { |q| q[:slow] },
      cache_hit_rate: cache_hit_rate,
      uptime_hours: ((Time.current - @metrics[:started_at]) / 1.hour).round(2)
    }
  end

  def cache_hit_rate
    total = @metrics[:cache_hits] + @metrics[:cache_misses]
    return 0.0 if total.zero?
    
    ((@metrics[:cache_hits].to_f / total) * 100).round(2)
  end

  def calculate_median(array)
    return 0 if array.empty?
    
    sorted = array.sort
    mid = sorted.length / 2
    
    if sorted.length.odd?
      sorted[mid]
    else
      ((sorted[mid - 1] + sorted[mid]) / 2.0).round(2)
    end
  end

  def calculate_percentile(array, percentile)
    return 0 if array.empty?
    
    sorted = array.sort
    index = (percentile / 100.0 * (sorted.length - 1)).round
    sorted[index]
  end
end
