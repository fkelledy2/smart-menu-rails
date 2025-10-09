# Background job for cache invalidation to improve response times
class CacheInvalidationJob < ApplicationJob
  queue_as :default
  
  # Retry with exponential backoff for Redis connectivity issues
  retry_on Redis::BaseError, wait: :exponentially_longer, attempts: 3
  
  # Only retry on IdentityCache errors if the constant exists
  if defined?(IdentityCache) && defined?(IdentityCache::UnsupportedOperation)
    retry_on IdentityCache::UnsupportedOperation, attempts: 2
  end
  
  def perform(order_id: nil, restaurant_id: nil, user_id: nil, menu_id: nil, employee_id: nil)
    Rails.logger.info("[CacheInvalidationJob] Starting cache invalidation for order:#{order_id} restaurant:#{restaurant_id} user:#{user_id}")
    
    start_time = Time.current
    
    begin
      # Invalidate order-specific caches
      if order_id
        AdvancedCacheService.invalidate_order_caches(order_id)
        invalidate_identity_cache_for_order(order_id)
      end
      
      # Invalidate restaurant caches (but be more selective)
      if restaurant_id
        invalidate_restaurant_caches_selectively(restaurant_id)
      end
      
      # Only invalidate user caches if explicitly requested, not as cascade
      # Skip restaurant cascade to prevent the excessive invalidation seen in logs
      if user_id && should_invalidate_user_cache?(user_id)
        AdvancedCacheService.invalidate_user_caches(user_id, skip_restaurant_cascade: true)
      end
      
      # Additional specific invalidations
      AdvancedCacheService.invalidate_menu_caches(menu_id) if menu_id
      AdvancedCacheService.invalidate_employee_caches(employee_id) if employee_id
      
      duration = ((Time.current - start_time) * 1000).round(2)
      Rails.logger.info("[CacheInvalidationJob] Completed cache invalidation in #{duration}ms")
      
    rescue => e
      Rails.logger.error("[CacheInvalidationJob] Cache invalidation failed: #{e.class} #{e.message}")
      # Don't re-raise - cache invalidation failures shouldn't break the application
    end
  end
  
  private
  
  def invalidate_identity_cache_for_order(order_id)
    # Safely handle IdentityCache invalidation
    begin
      if defined?(IdentityCache) && IdentityCache.respond_to?(:should_use_cache?) && IdentityCache.should_use_cache?
        Ordr.expire_cache_index(:id, order_id)
      end
    rescue => e
      # Handle all IdentityCache errors gracefully
      if defined?(IdentityCache::UnsupportedOperation) && e.is_a?(IdentityCache::UnsupportedOperation)
        Rails.logger.warn("[CacheInvalidationJob] IdentityCache operation not supported: #{e.message}")
      else
        Rails.logger.error("[CacheInvalidationJob] IdentityCache invalidation failed: #{e.message}")
      end
    end
  end
  
  def invalidate_restaurant_caches_selectively(restaurant_id)
    # Use the new selective method from AdvancedCacheService
    AdvancedCacheService.invalidate_restaurant_caches_selectively(restaurant_id)
  end
  
  def should_invalidate_user_cache?(user_id)
    # Only invalidate user cache if it hasn't been invalidated recently
    last_invalidation_key = "user_cache_invalidated:#{user_id}"
    last_invalidation = Rails.cache.read(last_invalidation_key)
    
    if last_invalidation.nil? || last_invalidation < 5.minutes.ago
      Rails.cache.write(last_invalidation_key, Time.current, expires_in: 10.minutes)
      true
    else
      Rails.logger.debug("[CacheInvalidationJob] Skipping user cache invalidation - recently invalidated")
      false
    end
  end
end
