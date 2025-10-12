# Application Performance Monitoring (APM) Initialization

# Initialize APM components if enabled
if Rails.application.config.enable_apm
  # Add middleware using Rails initializer to ensure proper timing
  Rails.application.initializer "apm.add_middleware", before: :build_middleware_stack do |app|
    app.config.middleware.use PerformanceTracker
  end
  
  Rails.application.config.after_initialize do
    # Setup database performance monitoring
    DatabasePerformanceMonitor.setup_monitoring
    
    # Schedule memory tracking (in production, this would be handled by a job scheduler)
    if Rails.env.development?
      # In development, track memory every minute for testing
      Thread.new do
        loop do
          sleep(Rails.application.config.memory_monitoring_interval)
          MemoryMonitoringService.track_memory_usage
        end
      end
    end
  end
end

# Log APM status
Rails.logger.info "[APM] Application Performance Monitoring #{Rails.application.config.enable_apm ? 'ENABLED' : 'DISABLED'}"
if Rails.application.config.enable_apm
  Rails.logger.info "[APM] Sample rate: #{Rails.application.config.apm_sample_rate * 100}%"
  Rails.logger.info "[APM] Slow query threshold: #{Rails.application.config.slow_query_threshold}ms"
end
