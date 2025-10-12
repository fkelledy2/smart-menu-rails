class PerformanceMonitoringJob < ApplicationJob
  queue_as :monitoring
  
  def perform
    return unless Rails.application.config.respond_to?(:enable_apm) && Rails.application.config.enable_apm
    
    check_response_time_regression
    check_memory_usage_spikes
    check_error_rate_increases
    check_slow_query_patterns
    track_current_memory_usage
    
  rescue => e
    Rails.logger.error "Performance monitoring job failed: #{e.message}"
  end
  
  private
  
  def check_response_time_regression
    current_avg = PerformanceMetricsService.calculate_avg_response_time(15.minutes)
    baseline_avg = PerformanceMetricsService.calculate_avg_response_time(24.hours, 1.week.ago)
    
    return if current_avg.zero? || baseline_avg.zero?
    
    increase_percentage = ((current_avg - baseline_avg) / baseline_avg * 100).round(2)
    
    if increase_percentage > 50 # 50% increase
      PerformanceAlertJob.perform_later(
        type: 'performance_regression',
        current_avg: current_avg,
        baseline_avg: baseline_avg,
        increase: increase_percentage,
        severity: 'high'
      )
    elsif increase_percentage > 25 # 25% increase
      PerformanceAlertJob.perform_later(
        type: 'performance_regression',
        current_avg: current_avg,
        baseline_avg: baseline_avg,
        increase: increase_percentage,
        severity: 'medium'
      )
    end
  end
  
  def check_memory_usage_spikes
    current_memory = MemoryMonitoringService.current_memory_snapshot
    return unless current_memory[:rss_memory]
    
    # Check if memory usage is significantly higher than usual
    avg_memory = MemoryMetric.recent(24.hours).average(:rss_memory)
    return unless avg_memory
    
    increase_percentage = ((current_memory[:rss_memory] - avg_memory) / avg_memory * 100).round(2)
    
    if increase_percentage > 100 # 100% increase (double the memory)
      PerformanceAlertJob.perform_later(
        type: 'memory_spike',
        current_memory: current_memory[:formatted_rss],
        avg_memory: MemoryMonitoringService.format_memory_size(avg_memory),
        increase: increase_percentage,
        severity: 'critical'
      )
    elsif increase_percentage > 50 # 50% increase
      PerformanceAlertJob.perform_later(
        type: 'memory_spike',
        current_memory: current_memory[:formatted_rss],
        avg_memory: MemoryMonitoringService.format_memory_size(avg_memory),
        increase: increase_percentage,
        severity: 'high'
      )
    end
  end
  
  def check_error_rate_increases
    current_error_rate = PerformanceMetricsService.calculate_error_rate(15.minutes)
    baseline_error_rate = PerformanceMetricsService.calculate_error_rate(24.hours, 1.week.ago)
    
    return if current_error_rate.zero?
    
    if current_error_rate > 10 # More than 10% error rate
      PerformanceAlertJob.perform_later(
        type: 'high_error_rate',
        current_rate: current_error_rate,
        baseline_rate: baseline_error_rate,
        severity: 'critical'
      )
    elsif current_error_rate > 5 # More than 5% error rate
      PerformanceAlertJob.perform_later(
        type: 'high_error_rate',
        current_rate: current_error_rate,
        baseline_rate: baseline_error_rate,
        severity: 'high'
      )
    elsif baseline_error_rate > 0 && current_error_rate > baseline_error_rate * 3
      # Error rate tripled
      PerformanceAlertJob.perform_later(
        type: 'error_rate_increase',
        current_rate: current_error_rate,
        baseline_rate: baseline_error_rate,
        severity: 'medium'
      )
    end
  end
  
  def check_slow_query_patterns
    recent_slow_queries = SlowQuery.recent(15.minutes)
    return if recent_slow_queries.empty?
    
    # Group by pattern and check for repeated slow queries
    patterns = recent_slow_queries.group_by { |q| SlowQuery.normalize_sql(q.sql) }
    
    patterns.each do |pattern, queries|
      if queries.count > 5 # Same slow query pattern repeated 5+ times
        avg_duration = queries.sum(&:duration) / queries.count
        
        PerformanceAlertJob.perform_later(
          type: 'repeated_slow_query',
          pattern: pattern.truncate(200),
          count: queries.count,
          avg_duration: avg_duration,
          severity: queries.count > 10 ? 'high' : 'medium'
        )
      end
    end
  end
  
  def track_current_memory_usage
    MemoryMonitoringService.track_memory_usage
  end
end
