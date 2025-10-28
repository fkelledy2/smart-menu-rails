# frozen_string_literal: true

# L1 Cache Optimization: Cache Metrics Service
# Collects and analyzes cache performance metrics
class CacheMetricsService
  # Metrics to track
  METRICS = %i[
    hit_rate miss_rate write_rate delete_rate
    memory_usage compression_ratio
    response_time throughput
    error_rate availability
    key_count pattern_distribution
  ].freeze

  # Time windows for metrics collection
  TIME_WINDOWS = {
    realtime: 1.minute,
    short: 5.minutes,
    medium: 1.hour,
    long: 24.hours,
  }.freeze

  class << self
    # Collect comprehensive cache metrics
    def collect_metrics(window: :medium)
      Rails.logger.debug { "[CacheMetricsService] Collecting metrics for window: #{window}" }

      {
        timestamp: Time.current.iso8601,
        window: window,
        duration: TIME_WINDOWS[window],
        performance: collect_performance_metrics(window),
        memory: collect_memory_metrics,
        operations: collect_operation_metrics(window),
        health: collect_health_metrics,
        patterns: collect_pattern_metrics,
        recommendations: generate_recommendations,
      }
    end

    # Get cache hit rate
    def calculate_hit_rate(window: :medium)
      hits = get_metric_value('cache_metrics:hits', window)
      misses = get_metric_value('cache_metrics:misses', window)
      total = hits + misses

      return 0.0 if total.zero?

      (hits.to_f / total * 100).round(2)
    end

    # Get cache miss rate
    def calculate_miss_rate(window: :medium)
      100.0 - calculate_hit_rate(window: window)
    end

    # Get cache throughput (operations per second)
    def calculate_throughput(window: :medium)
      duration_seconds = TIME_WINDOWS[window].to_i
      total_operations = calculate_total_operations(window: window)

      return 0.0 if duration_seconds.zero?

      (total_operations.to_f / duration_seconds).round(2)
    end

    # Get total cache operations
    def calculate_total_operations(window: :medium)
      hits = get_metric_value('cache_metrics:hits', window)
      misses = get_metric_value('cache_metrics:misses', window)
      writes = get_metric_value('cache_metrics:writes', window)
      deletes = get_metric_value('cache_metrics:deletes', window)

      hits + misses + writes + deletes
    end

    # Get cache error rate
    def calculate_error_rate(window: :medium)
      errors = get_metric_value('cache_metrics:errors', window)
      total_operations = calculate_total_operations(window: window)

      return 0.0 if total_operations.zero?

      (errors.to_f / total_operations * 100).round(2)
    end

    # Get memory usage statistics
    def get_memory_usage
      return {} unless redis_available?

      begin
        memory_info = Rails.cache.redis.memory('usage')

        {
          used_memory: memory_info['used_memory'],
          used_memory_human: memory_info['used_memory_human'],
          used_memory_peak: memory_info['used_memory_peak'],
          used_memory_peak_human: memory_info['used_memory_peak_human'],
          memory_fragmentation_ratio: memory_info['mem_fragmentation_ratio'],
          memory_efficiency: calculate_memory_efficiency(memory_info),
        }
      rescue StandardError => e
        Rails.logger.error("[CacheMetricsService] Failed to get memory usage: #{e.message}")
        {}
      end
    end

    # Get compression ratio
    def calculate_compression_ratio
      # This would require tracking compressed vs uncompressed sizes
      # For now, return estimated ratio based on configuration
      compression_threshold = Rails.cache.options[:compression_threshold] || 1024

      if compression_threshold.positive?
        # Estimate based on typical compression ratios
        0.65 # 65% of original size (35% compression)
      else
        1.0 # No compression
      end
    end

    # Measure cache response time
    def measure_response_time(operation: :read, samples: 10)
      return 0.0 unless redis_available?

      times = []

      samples.times do
        start_time = Time.current

        case operation
        when :read
          Rails.cache.read("benchmark_key_#{rand(1000)}")
        when :write
          Rails.cache.write("benchmark_key_#{rand(1000)}", 'benchmark_value', expires_in: 1.minute)
        when :delete
          Rails.cache.delete("benchmark_key_#{rand(1000)}")
        end

        times << ((Time.current - start_time) * 1000).round(2)
      end

      times.sum / times.size
    rescue StandardError => e
      Rails.logger.error("[CacheMetricsService] Failed to measure response time: #{e.message}")
      0.0
    end

    # Get cache availability
    def check_availability
      return false unless redis_available?

      begin
        Rails.cache.write('health_check', Time.current.to_i, expires_in: 1.minute)
        value = Rails.cache.read('health_check')
        Rails.cache.delete('health_check')

        !value.nil?
      rescue StandardError => e
        Rails.logger.error("[CacheMetricsService] Cache availability check failed: #{e.message}")
        false
      end
    end

    # Get cache key count by pattern
    def get_key_count_by_pattern
      return {} unless redis_available?

      patterns = {
        'restaurant:*' => 0,
        'menu:*' => 0,
        'order:*' => 0,
        'employee:*' => 0,
        'user:*' => 0,
        'analytics:*' => 0,
      }

      begin
        patterns.each do |pattern, _|
          namespace = Rails.cache.options[:namespace]
          full_pattern = namespace ? "#{namespace}:#{pattern}" : pattern
          patterns[pattern] = Rails.cache.redis.keys(full_pattern).size
        end
      rescue StandardError => e
        Rails.logger.error("[CacheMetricsService] Failed to get key counts: #{e.message}")
      end

      patterns
    end

    # Reset cache metrics
    def reset_metrics
      METRICS.each do |metric|
        Rails.cache.write("cache_metrics:#{metric}", 0, expires_in: 1.week)
      end
      Rails.cache.write('cache_metrics:last_reset', Time.current.iso8601, expires_in: 1.week)

      Rails.logger.info('[CacheMetricsService] Cache metrics reset')
    end

    # Export metrics for external monitoring
    def export_metrics(format: :json)
      metrics = collect_metrics(window: :long)

      case format
      when :json
        metrics.to_json
      when :prometheus
        convert_to_prometheus_format(metrics)
      when :csv
        convert_to_csv_format(metrics)
      else
        metrics
      end
    end

    private

    # Collect performance metrics
    def collect_performance_metrics(window)
      {
        hit_rate: calculate_hit_rate(window: window),
        miss_rate: calculate_miss_rate(window: window),
        throughput: calculate_throughput(window: window),
        error_rate: calculate_error_rate(window: window),
        response_time: {
          read: measure_response_time(operation: :read, samples: 5),
          write: measure_response_time(operation: :write, samples: 5),
          delete: measure_response_time(operation: :delete, samples: 5),
        },
      }
    end

    # Collect memory metrics
    def collect_memory_metrics
      memory_usage = get_memory_usage

      {
        usage: memory_usage,
        compression_ratio: calculate_compression_ratio,
        efficiency: memory_usage[:memory_efficiency] || 0.0,
        fragmentation: memory_usage[:memory_fragmentation_ratio] || 1.0,
      }
    end

    # Collect operation metrics
    def collect_operation_metrics(window)
      {
        total_operations: calculate_total_operations(window: window),
        hits: get_metric_value('cache_metrics:hits', window),
        misses: get_metric_value('cache_metrics:misses', window),
        writes: get_metric_value('cache_metrics:writes', window),
        deletes: get_metric_value('cache_metrics:deletes', window),
        errors: get_metric_value('cache_metrics:errors', window),
      }
    end

    # Collect health metrics
    def collect_health_metrics
      {
        availability: check_availability,
        redis_connected: redis_available?,
        last_reset: Rails.cache.read('cache_metrics:last_reset') || 'Never',
        uptime: calculate_uptime,
      }
    end

    # Collect pattern metrics
    def collect_pattern_metrics
      {
        key_counts: get_key_count_by_pattern,
        total_keys: get_key_count_by_pattern.values.sum,
        pattern_distribution: calculate_pattern_distribution,
      }
    end

    # Generate optimization recommendations
    def generate_recommendations
      recommendations = []

      hit_rate = calculate_hit_rate
      error_rate = calculate_error_rate
      memory_usage = get_memory_usage

      if hit_rate < 90.0
        recommendations << {
          type: 'performance',
          priority: 'high',
          message: "Cache hit rate is #{hit_rate}% (target: >90%). Consider cache warming or longer expiration times.",
        }
      end

      if error_rate > 1.0
        recommendations << {
          type: 'reliability',
          priority: 'high',
          message: "Cache error rate is #{error_rate}% (target: <1%). Check Redis connectivity and memory.",
        }
      end

      if memory_usage[:memory_fragmentation_ratio] && memory_usage[:memory_fragmentation_ratio] > 1.5
        recommendations << {
          type: 'memory',
          priority: 'medium',
          message: "Memory fragmentation ratio is #{memory_usage[:memory_fragmentation_ratio]} (target: <1.5). Consider Redis restart.",
        }
      end

      recommendations
    end

    # Get metric value for time window
    def get_metric_value(metric_key, _window)
      # For now, return current value
      # In production, this would aggregate values over the time window
      Rails.cache.read(metric_key) || 0
    end

    # Check if Redis is available
    def redis_available?
      Rails.cache.respond_to?(:redis) && Rails.cache.redis.ping == 'PONG'
    rescue StandardError
      false
    end

    # Calculate memory efficiency
    def calculate_memory_efficiency(memory_info)
      return 0.0 unless memory_info['used_memory'] && memory_info['used_memory_peak']

      used = memory_info['used_memory'].to_f
      peak = memory_info['used_memory_peak'].to_f

      return 100.0 if peak.zero?

      (used / peak * 100).round(2)
    end

    # Calculate cache uptime
    def calculate_uptime
      last_reset = Rails.cache.read('cache_metrics:last_reset')
      return 'Unknown' unless last_reset

      begin
        reset_time = Time.zone.parse(last_reset)
        duration = Time.current - reset_time

        days = (duration / 1.day).to_i
        hours = ((duration % 1.day) / 1.hour).to_i
        minutes = ((duration % 1.hour) / 1.minute).to_i

        "#{days}d #{hours}h #{minutes}m"
      rescue StandardError
        'Unknown'
      end
    end

    # Calculate pattern distribution
    def calculate_pattern_distribution
      key_counts = get_key_count_by_pattern
      total_keys = key_counts.values.sum

      return {} if total_keys.zero?

      key_counts.transform_values do |count|
        (count.to_f / total_keys * 100).round(2)
      end
    end

    # Convert metrics to Prometheus format
    def convert_to_prometheus_format(metrics)
      prometheus_metrics = []

      # Add performance metrics
      prometheus_metrics << "cache_hit_rate #{metrics[:performance][:hit_rate]}"
      prometheus_metrics << "cache_miss_rate #{metrics[:performance][:miss_rate]}"
      prometheus_metrics << "cache_throughput #{metrics[:performance][:throughput]}"
      prometheus_metrics << "cache_error_rate #{metrics[:performance][:error_rate]}"

      # Add memory metrics
      if metrics[:memory][:usage][:used_memory]
        prometheus_metrics << "cache_memory_used #{metrics[:memory][:usage][:used_memory]}"
      end

      # Add operation metrics
      prometheus_metrics << "cache_operations_total #{metrics[:operations][:total_operations]}"
      prometheus_metrics << "cache_hits_total #{metrics[:operations][:hits]}"
      prometheus_metrics << "cache_misses_total #{metrics[:operations][:misses]}"

      prometheus_metrics.join("\n")
    end

    # Convert metrics to CSV format
    def convert_to_csv_format(metrics)
      require 'csv'

      CSV.generate do |csv|
        csv << %w[Metric Value Unit Timestamp]

        csv << ['Hit Rate', metrics[:performance][:hit_rate], '%', metrics[:timestamp]]
        csv << ['Miss Rate', metrics[:performance][:miss_rate], '%', metrics[:timestamp]]
        csv << ['Throughput', metrics[:performance][:throughput], 'ops/sec', metrics[:timestamp]]
        csv << ['Error Rate', metrics[:performance][:error_rate], '%', metrics[:timestamp]]
        csv << ['Total Operations', metrics[:operations][:total_operations], 'count', metrics[:timestamp]]
      end
    end
  end
end
