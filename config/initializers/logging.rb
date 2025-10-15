# Logging configuration for structured logging
Rails.application.configure do
  # Configure log level based on environment - reduced verbosity
  config.log_level = case Rails.env
                     when 'development'
                       :warn  # Reduced from :debug to :warn
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

  # Configure log tags for request tracking - reduced in development
  config.log_tags = if Rails.env.development?
    [] # Remove all tags in development to reduce noise
  else
    [
      :request_id,
      -> request { "IP:#{request.remote_ip}" },
      -> request { "User:#{request.env['warden']&.user&.id || 'anonymous'}" }
    ]
  end

  # Silence certain log messages in development
  if Rails.env.development?
    # Silence asset pipeline logs
    config.assets.quiet = true
    
    # Silence ActionView logs for partials
    config.action_view.logger = nil if config.respond_to?(:action_view)
  end

  # Configure ActiveRecord logging - reduced verbosity in development
  if defined?(ActiveRecord)
    # Disable ActiveRecord logging in development to reduce noise
    if Rails.env.development?
      ActiveRecord::Base.logger = nil
    end
    
    # Set slow query threshold (not available in Rails 7.1+)
    # config.active_record.slow_query_threshold = Rails.env.production? ? 1.0 : 0.5
  end
end

# Sentry logging configuration is handled in config/initializers/sentry.rb
