# Logging configuration for structured logging
Rails.application.configure do
  # Configure log level based on environment
  config.log_level = case Rails.env
                     when 'development'
                       :debug
                     when 'test'
                       :warn
                     when 'production'
                       :info
                     else
                       :info
                     end

  # Configure log formatter
  if Rails.env.production?
    # Use JSON formatter in production for log aggregation
    config.log_formatter = proc do |severity, timestamp, progname, msg|
      {
        timestamp: timestamp.iso8601(3),
        level: severity,
        progname: progname,
        message: msg
      }.to_json + "\n"
    end
  else
    # Use default formatter in development/test for readability
    config.log_formatter = ::Logger::Formatter.new
  end

  # Configure log tags for request tracking
  config.log_tags = [
    :request_id,
    -> request { "IP:#{request.remote_ip}" },
    -> request { "User:#{request.env['warden']&.user&.id || 'anonymous'}" }
  ]

  # Silence certain log messages in development
  if Rails.env.development?
    # Silence asset pipeline logs
    config.assets.quiet = true
    
    # Silence ActionView logs for partials
    config.action_view.logger = nil if config.respond_to?(:action_view)
  end

  # Configure ActiveRecord logging
  if defined?(ActiveRecord)
    # Log slow queries in development
    if Rails.env.development?
      ActiveRecord::Base.logger = ActiveSupport::TaggedLogging.new(
        ActiveSupport::Logger.new(STDOUT)
      )
    end
    
    # Set slow query threshold (not available in Rails 7.1+)
    # config.active_record.slow_query_threshold = Rails.env.production? ? 1.0 : 0.5
  end
end

# Configure Sentry logging if available
if defined?(Sentry) && Rails.env.production?
  Sentry.configure do |config|
    # Capture all log messages at error level and above
    config.breadcrumbs_logger = [:active_support_logger]
    
    # Set log level for Sentry
    config.logger.level = Logger::WARN
  end
end
