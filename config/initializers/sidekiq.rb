# Configure Sidekiq logging
Sidekiq.configure_server do |config|
  config.logger.level = Logger::WARN

  begin
    require 'sidekiq-scheduler'
    schedule_file = Rails.root.join('config', 'sidekiq.yml')
    if File.exist?(schedule_file)
      Sidekiq::Scheduler.dynamic = true if Sidekiq::Scheduler.respond_to?(:dynamic=)
      Sidekiq.schedule = YAML.load_file(schedule_file)[:schedule] || {} if Sidekiq.respond_to?(:schedule=)
      Sidekiq::Scheduler.reload_schedule! if Sidekiq::Scheduler.respond_to?(:reload_schedule!)
    end
  rescue LoadError
    # sidekiq-scheduler gem not available in this environment
  rescue StandardError => e
    Rails.logger.warn("[Sidekiq] Failed to load sidekiq-scheduler schedule: #{e.class}: #{e.message}")
  end
end

# Also configure the client side in case it's used directly
Sidekiq.configure_client do |config|
  config.logger.level = Logger::WARN
end
