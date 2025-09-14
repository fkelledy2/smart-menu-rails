# Configure Sidekiq logging
Sidekiq.configure_server do |config|
  config.logger.level = Logger::WARN
end

# Also configure the client side in case it's used directly
Sidekiq.configure_client do |config|
  config.logger.level = Logger::WARN
end
