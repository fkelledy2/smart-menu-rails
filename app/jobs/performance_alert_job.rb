class PerformanceAlertJob < ApplicationJob
  queue_as :alerts
  
  def perform(type:, severity:, **details)
    case type
    when 'slow_response'
      handle_slow_response_alert(details, severity)
    when 'server_error'
      handle_server_error_alert(details, severity)
    when 'memory_leak'
      handle_memory_leak_alert(details, severity)
    when 'performance_regression'
      handle_performance_regression_alert(details, severity)
    else
      Rails.logger.warn "Unknown performance alert type: #{type}"
    end
  end
  
  private
  
  def handle_slow_response_alert(details, severity)
    message = "Slow response detected: #{details[:endpoint]} took #{details[:response_time]}ms"
    
    Rails.logger.warn "[PERFORMANCE ALERT] #{message}"
    
    # In production, you might want to send to Slack, email, or monitoring service
    if Rails.env.production?
      # NotificationService.send_alert(
      #   type: 'performance',
      #   severity: severity,
      #   message: message,
      #   details: details
      # )
    end
  end
  
  def handle_server_error_alert(details, severity)
    message = "Server error detected: #{details[:endpoint]} returned #{details[:status_code]}"
    
    Rails.logger.error "[PERFORMANCE ALERT] #{message}"
    
    if Rails.env.production?
      # NotificationService.send_alert(
      #   type: 'error',
      #   severity: severity,
      #   message: message,
      #   details: details
      # )
    end
  end
  
  def handle_memory_leak_alert(details, severity)
    message = "Potential memory leak detected: #{details[:trend]} MB/hour increase"
    
    Rails.logger.error "[PERFORMANCE ALERT] #{message}"
    
    if Rails.env.production?
      # NotificationService.send_alert(
      #   type: 'memory',
      #   severity: severity,
      #   message: message,
      #   details: details
      # )
    end
  end
  
  def handle_performance_regression_alert(details, severity)
    message = "Performance regression detected: #{details[:endpoint]} is #{details[:increase]}% slower"
    
    Rails.logger.warn "[PERFORMANCE ALERT] #{message}"
    
    if Rails.env.production?
      # NotificationService.send_alert(
      #   type: 'regression',
      #   severity: severity,
      #   message: message,
      #   details: details
      # )
    end
  end
end
