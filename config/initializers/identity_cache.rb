# Configure IdentityCache
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

# Enable/disable cache based on environment
if defined?(IdentityCache::WithGlobalConfiguration)
  # For newer versions of identity_cache
  IdentityCache.configure do |config|
    config.enabled = Rails.env.production? || Rails.env.staging?
    # Silence delete warnings in development
    config.on_error = ->(error, operation, _data) do
      next if error.is_a?(IdentityCache::UnsupportedOperation) && operation == :delete
      Rails.logger.error("IdentityCache #{operation} failed: #{error.message}")
    end if Rails.env.development? || Rails.env.test?
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
