class ClearCacheJob
  include Sidekiq::Job

  sidekiq_options retry: 1, queue: :default

  def perform
    started_at = Time.current
    Rails.logger.info("[ClearCacheJob] Starting cache clear at #{started_at}")

    # Attempt to enumerate keys (Redis cache store only)
    keys_info = enumerate_cache_keys_safely
    if keys_info
      Rails.logger.info(
        "[ClearCacheJob] Keys (total=#{keys_info[:count]}), namespace='#{keys_info[:namespace] || 'none'}'",
      )
      if keys_info[:sample]&.any?
        Rails.logger.info("[ClearCacheJob] Sample keys (#{keys_info[:sample].size} shown):\n- #{keys_info[:sample].join("\n- ")}")
      end
    else
      Rails.logger.info('[ClearCacheJob] Cache store is not Redis-backed or key enumeration unavailable; proceeding to clear')
    end

    # Clear Rails cache (namespaced to cache store)
    Rails.cache.clear

    finished_at = Time.current
    Rails.logger.info("[ClearCacheJob] Cache cleared in #{(finished_at - started_at).round(2)}s")
  rescue StandardError => e
    Rails.logger.error("[ClearCacheJob] Failed: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    raise
  end

  private

  # Returns { count:, sample:, namespace: } or nil if not supported
  def enumerate_cache_keys_safely
    store = Rails.cache
    # Try to get namespace from options if present
    namespace = begin
      store.respond_to?(:options) ? store.options[:namespace] : nil
    rescue StandardError
      nil
    end

    # Prefer official Redis connection accessor if available
    pool = if store.respond_to?(:redis)
             store.redis # returns a connection pool proxy responding to :with
           else
             # Fallback to internal ivar (Rails < 6.1 or different impl)
             begin
               store.instance_variable_get(:@data)
             rescue StandardError
               nil
             end
           end
    return nil unless pool.respond_to?(:with)

    keys = []
    total = 0
    pattern = namespace ? "#{namespace}:*" : '*'

    pool.with do |conn|
      unless conn.respond_to?(:scan)
        Rails.logger.info("[ClearCacheJob] Cache connection does not support SCAN (#{conn.class}); skipping key enumeration")
        return nil
      end
      cursor = '0'
      loop do
        cursor, batch = conn.scan(cursor, match: pattern, count: 1000)
        total += batch.size
        # Keep a capped sample to avoid huge logs
        if keys.size < 200
          slice_needed = 200 - keys.size
          keys.concat(batch.take(slice_needed))
        end
        break if cursor == '0'
      end
    end

    { count: total, sample: keys, namespace: namespace }
  rescue StandardError => e
    Rails.logger.warn("[ClearCacheJob] Could not enumerate keys: #{e.class}: #{e.message}")
    nil
  end
end
