# Redis Performance Monitoring
# Monitor cache operations and log slow queries for optimization

if Rails.env.production? || Rails.env.staging?
  # Monitor slow cache reads
  ActiveSupport::Notifications.subscribe('cache_read.active_support') do |name, start, finish, id, payload|
    duration = finish - start
    
    if duration > 0.1 # Log slow cache reads (>100ms)
      Rails.logger.warn(
        "[Redis] Slow cache read: #{payload[:key]} took #{duration.round(3)}s " \
        "hit=#{payload[:hit]} super_operation=#{payload[:super_operation]}"
      )
    end
    
    # Track cache hit rates
    if Rails.env.production?
      hit_rate = payload[:hit] ? 1 : 0
      # You can send this to your metrics system (e.g., StatsD, DataDog)
      # StatsD.increment('cache.read.total')
      # StatsD.increment('cache.read.hit') if payload[:hit]
    end
  end
  
  # Monitor slow cache writes
  ActiveSupport::Notifications.subscribe('cache_write.active_support') do |name, start, finish, id, payload|
    duration = finish - start
    
    if duration > 0.2 # Log slow cache writes (>200ms)
      Rails.logger.warn(
        "[Redis] Slow cache write: #{payload[:key]} took #{duration.round(3)}s"
      )
    end
  end
  
  # Monitor cache deletes
  ActiveSupport::Notifications.subscribe('cache_delete.active_support') do |name, start, finish, id, payload|
    duration = finish - start
    
    if duration > 0.15 # Log slow cache deletes (>150ms)
      Rails.logger.warn(
        "[Redis] Slow cache delete: #{payload[:key]} took #{duration.round(3)}s"
      )
    end
  end
  
  # Monitor cache fetch operations (read + potential write)
  ActiveSupport::Notifications.subscribe('cache_fetch_hit.active_support') do |name, start, finish, id, payload|
    # Cache hit - good performance
    Rails.logger.debug("[Redis] Cache hit: #{payload[:key]}")
  end
  
  ActiveSupport::Notifications.subscribe('cache_generate.active_support') do |name, start, finish, id, payload|
    duration = finish - start
    
    if duration > 1.0 # Log slow cache generation (>1s)
      Rails.logger.warn(
        "[Redis] Slow cache generation: #{payload[:key]} took #{duration.round(3)}s"
      )
    end
  end
  
  # Log Redis connection issues
  ActiveSupport::Notifications.subscribe('cache_read.active_support') do |name, start, finish, id, payload|
    if payload[:exception]
      Rails.logger.error(
        "[Redis] Cache read error: #{payload[:exception].first} - #{payload[:exception].last}"
      )
    end
  end
end

# Development monitoring (less verbose)
if Rails.env.development?
  ActiveSupport::Notifications.subscribe('cache_read.active_support') do |name, start, finish, id, payload|
    duration = finish - start
    
    if duration > 0.5 # Only log very slow operations in development
      Rails.logger.debug(
        "[Redis] Cache read: #{payload[:key]} took #{duration.round(3)}s hit=#{payload[:hit]}"
      )
    end
  end
end
