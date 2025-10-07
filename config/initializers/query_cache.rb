# frozen_string_literal: true

# Query Cache Configuration
Rails.application.configure do
  # Enable query result caching in production and staging
  config.query_cache_enabled = Rails.env.production? || Rails.env.staging?
  
  # Configure cache warming schedule (if using background jobs)
  if config.query_cache_enabled
    Rails.logger.info "[QueryCache] Query result caching enabled for #{Rails.env} environment"
    
    # Schedule cache warming after application initialization
    config.after_initialize do
      # Warm cache on application startup (only in production)
      if Rails.env.production?
        Rails.logger.info "[QueryCache] Scheduling initial cache warming"
        
        # Use a background job if available, otherwise warm synchronously
        begin
          # Example: CacheWarmingJob.perform_later
          # For now, warm in background thread to avoid blocking startup
          Thread.new do
            sleep(30) # Wait for application to fully start
            CacheWarmingService.warm_all
          end
        rescue => e
          Rails.logger.error "[QueryCache] Failed to schedule cache warming: #{e.message}"
        end
      end
    end
  else
    Rails.logger.info "[QueryCache] Query result caching disabled for #{Rails.env} environment"
  end
end

# Configure cache monitoring in development
if Rails.env.development?
  # Add cache debugging middleware
  Rails.application.config.middleware.use(Class.new do
    def initialize(app)
      @app = app
    end
    
    def call(env)
      # Track cache performance for development debugging
      start_time = Time.current
      status, headers, response = @app.call(env)
      request_time = Time.current - start_time
      
      # Log slow requests that might benefit from caching
      if request_time > 0.5 && env['REQUEST_METHOD'] == 'GET'
        Rails.logger.warn "[QueryCache] Slow request detected: #{env['PATH_INFO']} (#{request_time.round(3)}s)"
      end
      
      [status, headers, response]
    end
  end)
end

# Cache invalidation hooks for model changes
Rails.application.config.to_prepare do
  # Add cache invalidation to models that affect cached queries
  
  if defined?(Restaurant)
    Restaurant.class_eval do
      after_update :invalidate_restaurant_query_cache
      after_destroy :invalidate_restaurant_query_cache
      
      private
      
      def invalidate_restaurant_query_cache
        QueryCacheService.clear_pattern("*restaurant_#{id}*")
        QueryCacheService.clear_pattern("*user_#{user_id}*") if user_id
      end
    end
  end
  
  if defined?(Ordr)
    Ordr.class_eval do
      after_create :invalidate_order_query_cache
      after_update :invalidate_order_query_cache
      after_destroy :invalidate_order_query_cache
      
      private
      
      def invalidate_order_query_cache
        QueryCacheService.clear_pattern("*restaurant_#{restaurant_id}*") if restaurant_id
        QueryCacheService.clear_pattern("*order_analytics*")
        QueryCacheService.clear_pattern("*dw_orders*")
      end
    end
  end
  
  if defined?(User)
    User.class_eval do
      after_update :invalidate_user_query_cache
      after_destroy :invalidate_user_query_cache
      
      private
      
      def invalidate_user_query_cache
        QueryCacheService.clear_pattern("*user_#{id}*")
      end
    end
  end
  
  if defined?(Metric)
    Metric.class_eval do
      after_create :invalidate_metrics_query_cache
      after_update :invalidate_metrics_query_cache
      after_destroy :invalidate_metrics_query_cache
      
      private
      
      def invalidate_metrics_query_cache
        QueryCacheService.clear_pattern("*metrics*")
        QueryCacheService.clear_pattern("*admin_summary*")
      end
    end
  end
end

# Schedule periodic cache warming (if using cron/whenever gem)
# Example cron schedule:
# every 1.hour do
#   runner "CacheWarmingService.warm_all"
# end
#
# every 5.minutes do
#   runner "CacheWarmingService.warm_metrics"
# end
