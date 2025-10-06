# frozen_string_literal: true

# Performance monitoring is temporarily disabled to fix loading issues
# TODO: Re-enable after fixing autoloading conflicts

# Only initialize performance monitoring in development and production
# if Rails.env.development? || Rails.env.production?
#   Rails.application.configure do
#     # Initialize after Rails is ready
#     config.after_initialize do
#       # Load and initialize performance monitoring if classes are available
#       begin
#         require Rails.root.join('app/services/performance_monitoring_service')
#         require Rails.root.join('app/middleware/performance_monitoring_middleware')
#         
#         # Add middleware dynamically (this won't work but keeping for reference)
#         # Rails.application.config.middleware.use PerformanceMonitoringMiddleware
#         
#         # Initialize performance monitoring service
#         PerformanceMonitoringService.instance
#         Rails.logger.info "[PERFORMANCE] Performance monitoring initialized"
#       rescue => e
#         Rails.logger.warn "[PERFORMANCE] Failed to initialize performance monitoring: #{e.message}"
#       end
#     end
#     
#     # Load query monitoring concern
#     config.to_prepare do
#       # Load query monitoring concern if ApplicationRecord exists
#       if defined?(ApplicationRecord)
#         begin
#           require Rails.root.join('app/models/concerns/query_monitoring')
#           ApplicationRecord.include QueryMonitoring unless ApplicationRecord.included_modules.include?(QueryMonitoring)
#           Rails.logger.info "[PERFORMANCE] Query monitoring included in ApplicationRecord"
#         rescue => e
#           Rails.logger.warn "[PERFORMANCE] Failed to load query monitoring: #{e.message}"
#         end
#       end
#     end
#   end
# end

Rails.logger.info "[PERFORMANCE] Performance monitoring is temporarily disabled"
