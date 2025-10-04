# Configure IdentityCache with optimized settings
IdentityCache.cache_backend = Rails.cache

# Set the logger and silence delete warnings in development
if Rails.env.development? || Rails.env.test?
  # Use a null logger for development to silence delete warnings
  require 'logger'
  dev_null = Logger.new(File::NULL)
  dev_null.level = Logger::WARN
  IdentityCache.logger = dev_null
else
  # Use Rails logger in other environments
  IdentityCache.logger = Rails.logger
end

# Enhanced IdentityCache configuration for performance
if defined?(IdentityCache::WithGlobalConfiguration)
  # For newer versions of identity_cache
  IdentityCache.configure do |config|
    config.enabled = Rails.env.production? || Rails.env.staging?
    
    # Performance optimizations
    config.cache_namespace = "smartmenu:#{Rails.env}:identity"
    config.fetch_read_only_records = true if config.respond_to?(:fetch_read_only_records=)
    
    # Enhanced error handling for Redis connectivity issues
    config.on_error = ->(error, operation, data) do
      # Silence delete warnings in development
      if Rails.env.development? || Rails.env.test?
        next if error.is_a?(IdentityCache::UnsupportedOperation) && operation == :delete
      end
      
      Rails.logger.error("IdentityCache #{operation} failed: #{error.message}")
      
      # Don't raise in production to maintain availability during Redis issues
      raise error unless Rails.env.production?
    end
  end
else
  # Fallback for older versions
  if IdentityCache.respond_to?(:should_use_cache=)
    IdentityCache.should_use_cache = Rails.env.production? || Rails.env.staging?
    # Silence delete warnings in development for older versions
    if Rails.env.development? || Rails.env.test?
      module IdentityCache
        def self.delete(key)
          super
        rescue IdentityCache::UnsupportedOperation => e
          # Silently ignore delete failures in development
        end
      end
    end
  end
end

# Note: Cache TTL should be configured in your cache store configuration
# For example, in config/environments/production.rb:
# config.cache_store = :redis_cache_store, {
#   url: ENV['REDIS_URL'],
#   expires_in: 1.hour
# }
