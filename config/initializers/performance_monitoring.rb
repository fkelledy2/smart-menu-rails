# frozen_string_literal: true

# Performance monitoring for production sluggishness issues
Rails.application.configure do
  # Monitor slow requests in production
  if Rails.env.production?
    config.after_initialize do
      # Log slow requests (over 2 seconds)
      ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, started, finished, unique_id, data|
        duration = finished - started
        if duration > 2.0  # 2 seconds threshold
          Rails.logger.warn "[SLOW REQUEST] #{data[:controller]}##{data[:action]} took #{(duration * 1000).round(2)}ms"
          Rails.logger.warn "[SLOW REQUEST] DB: #{data[:db_runtime]&.round(2)}ms (#{data[:db_query_count]} queries)"
          Rails.logger.warn "[SLOW REQUEST] View: #{data[:view_runtime]&.round(2)}ms"
        end
      end
      
      # Monitor N+1 queries
      ActiveSupport::Notifications.subscribe "sql.active_record" do |name, started, finished, unique_id, data|
        # Track query patterns that might indicate N+1 problems
        if data[:sql] =~ /SELECT.*FROM.*WHERE.*id.*IN/i
          Rails.logger.debug "[N+1 POTENTIAL] #{data[:sql].truncate(100)}"
        end
      end
      
      Rails.logger.info "[PERFORMANCE] Production performance monitoring enabled"
    end
  end
  
  # Cache performance monitoring
  config.to_prepare do
    if defined?(AdvancedCacheService)
      # Monitor cache hit rates
      Rails.application.config.cache_store_logger = Rails.logger
      Rails.logger.info "[PERFORMANCE] Cache monitoring enabled"
    end
  end
end
