class SlowQueryTrackingJob < ApplicationJob
  queue_as :monitoring

  def perform(sql:, duration:, timestamp:, query_name: nil, backtrace: [])
    # Create slow query record
    SlowQuery.create!(
      sql: sql,
      duration: duration,
      query_name: query_name,
      timestamp: timestamp,
      backtrace: backtrace.join("\n"),
    )

    # Check for critical slow queries
    check_critical_slow_queries(sql, duration)
  rescue StandardError => e
    # Log error but don't fail - APM shouldn't break the application
    Rails.logger.error "Failed to track slow query: #{e.message}"
  end

  private

  def check_critical_slow_queries(sql, duration)
    # Alert on extremely slow queries
    if duration > 10000 # 10 seconds
      PerformanceAlertJob.perform_later(
        type: 'critical_slow_query',
        sql: sql.truncate(500),
        duration: duration,
        severity: 'critical',
      )
    elsif duration > 5000 # 5 seconds
      PerformanceAlertJob.perform_later(
        type: 'slow_query',
        sql: sql.truncate(500),
        duration: duration,
        severity: 'high',
      )
    end
  end
end
