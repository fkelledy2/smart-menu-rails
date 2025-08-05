# Configure IdentityCache
IdentityCache.cache_backend = Rails.cache

# Set the logger
IdentityCache.logger = Rails.logger

# Enable/disable cache based on environment
if defined?(IdentityCache::WithGlobalConfiguration)
  # For newer versions of identity_cache
  IdentityCache.configure do |config|
    config.enabled = Rails.env.production? || Rails.env.staging?
  end
else
  # Fallback for older versions
  IdentityCache.should_use_cache = Rails.env.production? || Rails.env.staging? if IdentityCache.respond_to?(:should_use_cache=)
end

# Note: Cache TTL should be configured in your cache store configuration
# For example, in config/environments/production.rb:
# config.cache_store = :redis_cache_store, {
#   url: ENV['REDIS_URL'],
#   expires_in: 1.hour
# }
