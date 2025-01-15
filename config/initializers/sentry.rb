# frozen_string_literal: true

# Sentry.init do |config|
#   config.breadcrumbs_logger = [:active_support_logger]
#   config.dsn = ENV['SENTRY_DSN']
#   config.enable_tracing = true
# end

Sentry.init do |config|
  config.dsn = 'https://c05c8ef1a73fd432a1e5526ac4c1ada4@o4508649141895168.ingest.de.sentry.io/4508649144975440'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for tracing.
  # We recommend adjusting this value in production.
  config.traces_sample_rate = 1.0
  # or
  config.traces_sampler = lambda do |context|
    true
  end
  # Set profiles_sample_rate to profile 100%
  # of sampled transactions.
  # We recommend adjusting this value in production.
  config.profiles_sample_rate = 1.0
end