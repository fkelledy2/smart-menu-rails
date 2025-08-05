# config/initializers/cache_store.rb
# Unified cache-store setup with safe fallbacks and environment flags.

Rails.application.config.to_prepare do
  # Feature flag: allow quick rollback to Rails’ native store if needed
  use_redis_store = ENV.fetch("USE_REDIS_STORE", "true") == "true"

  # Build a per-environment Redis URL with sensible defaults
  default_db =
    case Rails.env
    when "production" then 0
    when "staging"    then 1
    when "development" then 2
    else 3 # test/other
    end

  redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/#{default_db}")

  # Namespacing prevents collisions across apps/environments
  namespace = ENV.fetch("CACHE_NAMESPACE", "#{Rails.application.class.module_parent_name.downcase}:#{Rails.env}:cache")

  # Common options
  redis_options = {
    url:        redis_url,
    namespace:  namespace,
    expires_in: ENV.fetch("CACHE_EXPIRES_IN", "43200").to_i, # 12 hours default
    # timeouts (be conservative for web requests)
    connect_timeout: ENV.fetch("CACHE_CONNECT_TIMEOUT", "1").to_f,   # seconds
    read_timeout:    ENV.fetch("CACHE_READ_TIMEOUT", "1.5").to_f,
    write_timeout:   ENV.fetch("CACHE_WRITE_TIMEOUT", "1.5").to_f,
    reconnect_attempts: ENV.fetch("CACHE_RECONNECT_ATTEMPTS", "1").to_i
  }

  # SSL if your Redis requires it (e.g., managed services)
  if ENV["REDIS_SSL"] == "true" && redis_url.start_with?("rediss://")
    redis_options[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE } unless ENV["REDIS_VERIFY_SSL"] == "true"
  end

  begin
    if use_redis_store
      Rails.logger.info("[cache] Using :redis_store (redis-activesupport) at #{redis_url} ns=#{namespace}")
      Rails.application.config.cache_store = :redis_store, redis_options
    else
      # Quick rollback option:
      Rails.logger.warn("[cache] USE_REDIS_STORE=false -> using :redis_cache_store (no CAS)")
      Rails.application.config.cache_store = :redis_cache_store, redis_options.except(:namespace)
    end

    # Safety: disable AR cache versioning if the store doesn’t support it
    # (redis-store may not advertise support; IdentityCache doesn't need AR versioning)
    store = ActiveSupport::Cache.lookup_store(*Array(Rails.application.config.cache_store))
    supports_versioning = store.respond_to?(:supports_cache_versioning?) && store.supports_cache_versioning?
    if !supports_versioning && Rails.application.config.respond_to?(:active_record)
      Rails.application.config.active_record.cache_versioning = false
      Rails.logger.info("[cache] active_record.cache_versioning = false")
    end

  rescue => e
    Rails.logger.error("[cache] Failed to initialize Redis cache store: #{e.class} #{e.message}")
    Rails.logger.warn("[cache] Falling back to :memory_store")
    Rails.application.config.cache_store = :memory_store, { size: 64.megabytes }
    # Also disable AR versioning with memory store:
    if Rails.application.config.respond_to?(:active_record)
      Rails.application.config.active_record.cache_versioning = false
    end
  end
end
