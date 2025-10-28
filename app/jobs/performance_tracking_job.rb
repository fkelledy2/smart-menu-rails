class PerformanceTrackingJob < ApplicationJob
  queue_as :monitoring

  def perform(endpoint:, response_time:, memory_usage:, status_code:, timestamp:, user_id: nil, controller: nil,
              action: nil, additional_data: {})
    # Create performance metric record
    PerformanceMetric.create!(
      endpoint: endpoint,
      response_time: response_time,
      memory_usage: memory_usage,
      status_code: status_code,
      user_id: user_id,
      controller: controller,
      action: action,
      timestamp: timestamp,
      additional_data: additional_data,
    )

    # Check for performance alerts
    check_performance_alerts(endpoint, response_time, status_code)
  rescue StandardError => e
    # Log error but don't fail - APM shouldn't break the application
    Rails.logger.error "Failed to track performance metric: #{e.message}"
  end

  private

  def check_performance_alerts(endpoint, response_time, status_code)
    # Alert on very slow responses
    if response_time > 5000 # 5 seconds
      PerformanceAlertJob.perform_later(
        type: 'slow_response',
        endpoint: endpoint,
        response_time: response_time,
        severity: 'critical',
      )
    elsif response_time > 2000 # 2 seconds
      PerformanceAlertJob.perform_later(
        type: 'slow_response',
        endpoint: endpoint,
        response_time: response_time,
        severity: 'warning',
      )
    end

    # Alert on server errors
    return unless status_code >= 500

    PerformanceAlertJob.perform_later(
      type: 'server_error',
      endpoint: endpoint,
      status_code: status_code,
      severity: 'high',
    )
  end
end
