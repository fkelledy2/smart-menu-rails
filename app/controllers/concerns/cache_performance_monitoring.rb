# Cache performance monitoring for controllers
module CachePerformanceMonitoring
  extend ActiveSupport::Concern

  included do
    # Track cache performance for key actions
    around_action :monitor_cache_performance, only: %i[show index]
  end

  private

  def monitor_cache_performance
    return yield unless Rails.env.production? || Rails.env.staging?

    start_time = Time.current
    cache_hits_before = get_cache_hits

    yield

    execution_time = Time.current - start_time
    cache_hits_after = get_cache_hits
    cache_hits_during_request = cache_hits_after - cache_hits_before

    # Log performance metrics
    Rails.logger.info("[CachePerformance] #{controller_name}##{action_name} - " \
                      "Time: #{execution_time.round(3)}s, " \
                      "Cache hits: #{cache_hits_during_request}, " \
                      "User: #{current_user&.id || 'anonymous'}")

    # Track slow requests
    if execution_time > 1.0
      Rails.logger.warn("[CachePerformance] SLOW REQUEST: #{controller_name}##{action_name} - " \
                        "#{execution_time.round(3)}s")
    end

    # Store metrics for dashboard
    store_performance_metrics(execution_time, cache_hits_during_request)
  rescue StandardError => e
    Rails.logger.error("[CachePerformance] Monitoring failed: #{e.message}")
    # Don't let monitoring errors affect the request
  end

  def get_cache_hits
    # Get current cache hit count from AdvancedCacheService
    AdvancedCacheService.cache_stats[:hits] || 0
  rescue StandardError
    0
  end

  def store_performance_metrics(execution_time, cache_hits)
    # Store in Redis for dashboard display
    metrics_key = "performance_metrics:#{Date.current}"

    Rails.cache.write(
      "#{metrics_key}:#{controller_name}:#{action_name}:#{Time.current.to_i}",
      {
        controller: controller_name,
        action: action_name,
        execution_time: execution_time,
        cache_hits: cache_hits,
        user_id: current_user&.id,
        timestamp: Time.current.iso8601,
      },
      expires_in: 7.days,
    )
  rescue StandardError => e
    Rails.logger.error("[CachePerformance] Failed to store metrics: #{e.message}")
  end

  # Class methods for retrieving performance data
  module ClassMethods
    def cache_performance_summary(days: 7)
      end_date = Date.current
      start_date = end_date - days.days

      metrics = []
      (start_date..end_date).each do |date|
        pattern = "performance_metrics:#{date}:*"
        keys = begin
          Rails.cache.redis.keys(pattern)
        rescue StandardError
          []
        end

        keys.each do |key|
          metric = Rails.cache.read(key)
          metrics << metric if metric
        end
      end

      # Aggregate by controller/action
      summary = metrics.group_by { |m| "#{m[:controller]}##{m[:action]}" }
        .transform_values do |controller_metrics|
        {
          count: controller_metrics.count,
          avg_time: controller_metrics.sum { |m| m[:execution_time] } / controller_metrics.count,
          max_time: controller_metrics.map { |m| m[:execution_time] }.max,
          avg_cache_hits: controller_metrics.sum { |m| m[:cache_hits] } / controller_metrics.count,
          total_cache_hits: controller_metrics.sum { |m| m[:cache_hits] },
        }
      end

      summary.sort_by { |_, stats| -stats[:avg_time] }
    rescue StandardError => e
      Rails.logger.error("[CachePerformance] Failed to generate summary: #{e.message}")
      {}
    end
  end
end
