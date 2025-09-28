"""
Sentry configuration
 - Disabled in test (and other non-enabled envs) to avoid network calls during CI/tests
 - DSN pulled from ENV['SENTRY_DSN'] if present
 - Enabled only for production/staging by default
"""

if defined?(Sentry)
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.enabled_environments = %w[production staging]
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    # Tracing (tune as needed per environment)
    config.traces_sample_rate = 1.0
    config.traces_sampler = lambda { |_context| true }
    config.profiles_sample_rate = 1.0
  end
end