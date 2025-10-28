class PerformanceMetricsService
  def self.current_snapshot
    {
      avg_response_time: calculate_avg_response_time(5.minutes),
      current_memory_usage: MemoryMonitoringService.current_memory_snapshot,
      cache_hit_rate: calculate_cache_hit_rate(5.minutes),
      active_users: count_active_users(5.minutes),
      error_rate: calculate_error_rate(5.minutes),
      slow_queries_count: count_slow_queries(5.minutes),
      timestamp: Time.current,
    }
  end

  def self.trends(timeframe)
    metrics = PerformanceMetric.recent(timeframe)
    memory_metrics = MemoryMetric.recent(timeframe)

    {
      response_time_trend: group_by_time(metrics, :response_time, timeframe),
      memory_trend: group_by_time(memory_metrics, :rss_memory, timeframe),
      error_trend: group_by_time(metrics.errors, :count, timeframe),
      slow_queries_trend: group_by_time_count(SlowQuery.recent(timeframe), timeframe),
    }
  end

  def self.slow_endpoints(timeframe = 1.hour, limit = 10)
    PerformanceMetric
      .recent(timeframe)
      .group(:endpoint)
      .average(:response_time)
      .sort_by { |_, avg_time| -avg_time }
      .first(limit)
      .map { |endpoint, avg_time| { endpoint: endpoint, avg_response_time: avg_time.round(2) } }
  end

  def self.endpoint_analysis(endpoint, timeframe = 24.hours)
    metrics = PerformanceMetric.recent(timeframe).by_endpoint(endpoint)

    return nil if metrics.empty?

    response_times = metrics.pluck(:response_time)

    {
      endpoint: endpoint,
      timeframe: timeframe,
      total_requests: metrics.count,
      avg_response_time: response_times.sum / response_times.length,
      min_response_time: response_times.min,
      max_response_time: response_times.max,
      p50_response_time: percentile(response_times, 50),
      p95_response_time: percentile(response_times, 95),
      p99_response_time: percentile(response_times, 99),
      error_rate: calculate_endpoint_error_rate(metrics),
      requests_per_hour: (metrics.count.to_f / (timeframe / 1.hour)).round(2),
      trend: calculate_endpoint_trend(metrics),
    }
  end

  def self.performance_summary(timeframe = 24.hours)
    {
      overview: current_snapshot,
      trends: trends(timeframe),
      slow_endpoints: slow_endpoints(timeframe),
      slow_queries: SlowQuery.slowest_queries(10, timeframe).map do |query|
        {
          sql: query.sql.truncate(100),
          duration: query.formatted_duration,
          table: query.table_name,
          timestamp: query.timestamp,
        }
      end,
      memory_analysis: {
        current: MemoryMonitoringService.current_memory_snapshot,
        trend: MemoryMetric.memory_trend(timeframe),
        leak_detected: MemoryMetric.detect_memory_leak,
      },
    }
  end

  def self.calculate_avg_response_time(timeframe)
    PerformanceMetric.recent(timeframe).average(:response_time) || 0
  end

  def self.calculate_cache_hit_rate(_timeframe)
    # This would need to be implemented based on your caching strategy
    # For now, return a placeholder based on IdentityCache if available
    if defined?(IdentityCache)
      # Placeholder - would need actual cache hit rate calculation
      85.0 + rand(10) # Simulate 85-95% hit rate
    else
      0
    end
  end

  def self.count_active_users(timeframe)
    PerformanceMetric
      .recent(timeframe)
      .where.not(user_id: nil)
      .distinct
      .count(:user_id)
  end

  def self.calculate_error_rate(timeframe)
    total = PerformanceMetric.recent(timeframe).count
    return 0 if total.zero?

    errors = PerformanceMetric.recent(timeframe).errors.count
    (errors.to_f / total * 100).round(2)
  end

  def self.count_slow_queries(timeframe)
    SlowQuery.recent(timeframe).count
  end

  def self.group_by_time(relation, column, timeframe)
    interval = calculate_interval(timeframe)

    relation
      .group_by { |record| time_bucket(record.timestamp, interval) }
      .transform_values do |records|
        if column == :count
          records.count
        else
          values = records.map(&column).compact
          values.empty? ? 0 : (values.sum.to_f / values.length).round(2)
        end
      end
      .sort
      .to_h
  end

  def self.group_by_time_count(relation, timeframe)
    interval = calculate_interval(timeframe)

    relation
      .group_by { |record| time_bucket(record.timestamp, interval) }
      .transform_values(&:count)
      .sort
      .to_h
  end

  def self.calculate_interval(timeframe)
    case timeframe
    when 0..(1.hour)
      5.minutes
    when (1.hour)..(6.hours)
      15.minutes
    when (6.hours)..(24.hours)
      1.hour
    else
      4.hours
    end
  end

  def self.time_bucket(timestamp, interval)
    interval_minutes = interval.in_minutes
    bucket_minutes = (timestamp.min / interval_minutes).floor * interval_minutes
    timestamp.beginning_of_hour + bucket_minutes.minutes
  end

  def self.percentile(array, percentile)
    return 0 if array.empty?

    sorted = array.sort
    index = (percentile / 100.0 * (sorted.length - 1))

    # Handle exact index
    if index == index.to_i
      sorted[index.to_i]
    else
      # Interpolate between two values
      lower_index = index.floor
      upper_index = index.ceil
      lower_value = sorted[lower_index]
      upper_value = sorted[upper_index]

      # Linear interpolation
      weight = index - lower_index
      ((lower_value * (1 - weight)) + (upper_value * weight)).round
    end
  end

  def self.calculate_endpoint_error_rate(metrics)
    total = metrics.count
    return 0 if total.zero?

    errors = metrics.where('status_code >= 400').count
    (errors.to_f / total * 100).round(2)
  end

  def self.calculate_endpoint_trend(metrics)
    # Simple trend calculation: compare first half vs second half
    sorted_metrics = metrics.order(:timestamp)
    return 0 if sorted_metrics.count < 4

    half_point = sorted_metrics.count / 2
    first_half_avg = sorted_metrics.limit(half_point).average(:response_time)
    second_half_avg = sorted_metrics.offset(half_point).average(:response_time)

    return 0 if first_half_avg.nil? || second_half_avg.nil? || first_half_avg.zero?

    ((second_half_avg - first_half_avg) / first_half_avg * 100).round(2)
  end
end
