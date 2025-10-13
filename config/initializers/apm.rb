# Application Performance Monitoring (APM) Configuration

Rails.application.configure do
  # APM Configuration
  config.enable_apm = Rails.env.production? || Rails.env.development? || (Rails.env.test? && ENV['ENABLE_APM_TESTS'])
  config.apm_sample_rate = Rails.env.production? ? 1.0 : 0.1 # Sample 100% in production, 10% in development
  config.slow_query_threshold = Rails.env.production? ? 100 : 50 # milliseconds
  config.memory_monitoring_interval = 60 # seconds
  config.performance_alert_threshold = 1.5 # 50% increase triggers alert
  config.memory_leak_threshold = 50 # MB per hour
  
  # Note: Performance tracking middleware disabled during startup to avoid class loading issues
  # The middleware functionality is replaced by manual job triggering in tests
end

# Initialize APM components if enabled
if Rails.application.config.enable_apm
  Rails.application.config.after_initialize do
    begin
      # Setup database performance monitoring
      DatabasePerformanceMonitor.setup_monitoring
      Rails.logger.info "[APM] Database performance monitoring initialized"
      
      # Schedule memory tracking (in production, this would be handled by a job scheduler)
      if Rails.env.development?
        # In development, track memory every minute for testing
        Thread.new do
          loop do
            sleep(Rails.application.config.memory_monitoring_interval)
            MemoryMonitoringService.track_memory_usage
          end
        end
        Rails.logger.info "[APM] Memory monitoring thread started"
      end
    rescue => e
      Rails.logger.error "[APM] Failed to initialize APM components: #{e.message}"
      Rails.logger.error "[APM] Backtrace: #{e.backtrace.first(5).join('\n')}"
    end
  end
end

# Log APM status
Rails.logger.info "[APM] Application Performance Monitoring #{Rails.application.config.enable_apm ? 'ENABLED' : 'DISABLED'}"
if Rails.application.config.enable_apm
  Rails.logger.info "[APM] Sample rate: #{Rails.application.config.apm_sample_rate * 100}%"
  Rails.logger.info "[APM] Slow query threshold: #{Rails.application.config.slow_query_threshold}ms"
end
