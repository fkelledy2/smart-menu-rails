# Sentry Error Tracking Configuration
# - Disabled in test (and other non-enabled envs) to avoid network calls during CI/tests
# - DSN pulled from ENV['SENTRY_DSN'] if present
# - Enabled only for production/staging by default
# - Enhanced with performance monitoring and user context

if defined?(Sentry)
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.enabled_environments = %w[production staging]
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    # Set release version for better tracking
    config.release = ENV['HEROKU_SLUG_COMMIT'] || ENV['GIT_COMMIT'] || 'unknown'
    
    # Environment-specific configuration
    config.environment = Rails.env
    
    # Performance monitoring - adjust sample rates for production
    if Rails.env.production?
      config.traces_sample_rate = 0.1  # 10% sampling in production
      config.profiles_sample_rate = 0.1  # 10% profiling in production
    else
      config.traces_sample_rate = 1.0  # 100% sampling in staging
      config.profiles_sample_rate = 1.0  # 100% profiling in staging
    end

    # Filter sensitive data
    config.before_send = lambda do |event, hint|
      # Filter out sensitive parameters
      if event.request&.data
        event.request.data = event.request.data.except(
          'password', 'password_confirmation', 'current_password',
          'credit_card_number', 'cvv', 'ssn', 'api_key', 'access_token'
        )
      end
      
      # Skip certain exceptions that are not actionable
      if hint[:exception]
        case hint[:exception]
        when ActionController::RoutingError, ActionController::BadRequest
          return nil if Rails.env.production?
        end
      end
      
      event
    end

    # Set user context for better debugging
    config.before_send_transaction = lambda do |event, hint|
      # Add custom tags for better filtering
      event.set_tag('component', 'rails')
      event.set_tag('server_name', ENV['DYNO'] || Socket.gethostname)
      event
    end

    # Configure which exceptions to ignore
    config.excluded_exceptions += [
      'ActionController::BadRequest',
      'ActionController::UnknownFormat',
      'ActionDispatch::RemoteIp::IpSpoofAttackError',
      'Rack::QueryParser::InvalidParameterError'
    ]

    # Note: Async processing is now handled by Sentry's background worker by default
    # Custom async processing can be added if needed, but it's not required for basic functionality
  end

  # User context will be added via ApplicationController concern
end