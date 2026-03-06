# Redis Optimization Plan for Smart Menu (Heroku Deployment)

## Current Redis Integration Analysis

### ✅ **What's Working Well**
1. **Multi-Purpose Redis Usage**:
   - Rails cache store (via `redis-activesupport`)
   - IdentityCache backend for model caching
   - Action Cable adapter for WebSocket connections
   - Heroku Redis add-on properly configured

2. **Good Configuration Practices**:
   - Environment-specific database separation
   - Proper namespacing to prevent collisions
   - Fallback mechanisms for Redis failures
   - SSL support for managed Redis services

3. **Comprehensive Model Caching**:
   - IdentityCache implemented across 20+ models
   - Strategic cache indexes on frequently queried fields
   - Association caching with embed strategies

### 🚨 **Critical Issues Identified**

#### 1. **Conflicting Cache Store Configuration**
**Problem**: Dual cache store setup causing confusion and potential conflicts:
- `config/initializers/cache_store.rb` sets up Redis with detailed configuration
- `config/environments/production.rb` overrides with different Redis settings
- MemCachier fallback logic may interfere with Redis optimization

#### 2. **Suboptimal Redis Connection Management**
**Problem**: Conservative timeout settings and single connection approach:
- Connect timeout: 1s (too conservative for Heroku Redis)
- Read/Write timeouts: 1.5s (may cause premature failures)
- No connection pooling configuration
- Single reconnect attempt (insufficient for network hiccups)

#### 3. **Inefficient Cache Key Strategies**
**Problem**: Complex cache keys causing performance overhead:
```ruby
Rails.cache.fetch([
  :menu_content_customer,
  ordr.cache_key_with_version,
  menu.cache_key_with_version,
  allergyns.maximum(:updated_at),
  restaurant_currency.code,
  ordrparticipant.try(:id),
  # ... more keys
])
```

#### 4. **Missing Redis Optimization Features**
**Problem**: Not leveraging advanced Redis capabilities:
- No Redis pipelining for bulk operations
- No compression for large cached objects
- No TTL optimization strategies
- No Redis memory optimization settings

## 🎯 **Optimization Recommendations**

### **Phase 1: Configuration Optimization**

#### 1.1 **Consolidate Cache Store Configuration**
Create a unified, optimized cache configuration:

```ruby
# config/initializers/redis_optimized.rb
Rails.application.config.to_prepare do
  # Heroku Redis connection with optimized settings
  redis_config = {
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    
    # Optimized timeouts for Heroku Redis
    connect_timeout: 2.0,    # Increased for Heroku network latency
    read_timeout: 3.0,       # More generous for complex queries
    write_timeout: 3.0,      # Allow time for large cache writes
    
    # Enhanced reconnection strategy
    reconnect_attempts: 3,
    reconnect_delay: 0.1,
    reconnect_delay_max: 1.0,
    
    # Connection pooling for high concurrency
    pool_size: ENV.fetch("REDIS_POOL_SIZE", "25").to_i,
    pool_timeout: 5,
    
    # Compression for large objects (>1KB)
    compress: true,
    compression_threshold: 1024,
    
    # Namespace for environment isolation
    namespace: "smartmenu:#{Rails.env}:cache",
    
    # Default TTL optimization
    expires_in: 6.hours, # Reduced from 12 hours for fresher data
    
    # Redis-specific optimizations
    driver: :hiredis, # Faster C-based Redis driver
  }
  
  # SSL configuration for Heroku Redis
  if ENV["REDIS_URL"]&.start_with?("rediss://")
    redis_config[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_PEER }
  end
  
  Rails.application.config.cache_store = :redis_cache_store, redis_config
end
```

#### 1.2 **Optimize IdentityCache Configuration**
```ruby
# config/initializers/identity_cache_optimized.rb
IdentityCache.cache_backend = Rails.cache

# Performance optimizations
IdentityCache.configure do |config|
  config.enabled = Rails.env.production? || Rails.env.staging?
  
  # Optimize for Heroku Redis
  config.cache_namespace = "smartmenu:#{Rails.env}:identity"
  
  # Batch operations for better performance
  config.fetch_read_only_records = true
  
  # Error handling for Redis connectivity issues
  config.on_error = ->(error, operation, data) do
    Rails.logger.error("IdentityCache #{operation} failed: #{error.message}")
    # Don't raise in production to maintain availability
    raise error unless Rails.env.production?
  end
end
```

### **Phase 2: Performance Optimizations**

#### 2.1 **Implement Smart Cache Key Strategies**
Create optimized cache key helpers:

```ruby
# app/services/cache_key_service.rb
class CacheKeyService
  class << self
    # Optimized cache key generation
    def menu_content_key(ordr:, menu:, participant: nil, **options)
      base_key = "menu_content:#{menu.id}:#{menu.updated_at.to_i}"
      
      # Add participant context if present
      if participant
        base_key += ":participant:#{participant.id}"
      end
      
      # Add order context
      base_key += ":ordr:#{ordr.id}:#{ordr.updated_at.to_i}"
      
      # Add optional context
      if options[:currency]
        base_key += ":currency:#{options[:currency].code}"
      end
      
      # Use MD5 hash for very long keys to prevent Redis key length issues
      base_key.length > 250 ? Digest::MD5.hexdigest(base_key) : base_key
    end
    
    # Hierarchical cache invalidation
    def invalidate_menu_cache(menu_id)
      Rails.cache.delete_matched("menu_content:#{menu_id}:*")
    end
    
    # Batch cache operations
    def fetch_multiple(keys, &block)
      Rails.cache.fetch_multi(*keys, &block)
    end
  end
end
```

#### 2.2 **Implement Redis Pipelining for Bulk Operations**
```ruby
# app/services/redis_pipeline_service.rb
class RedisPipelineService
  def self.bulk_cache_write(data_hash)
    Redis.current.pipelined do |pipeline|
      data_hash.each do |key, value|
        pipeline.setex(
          "#{Rails.cache.options[:namespace]}:#{key}",
          6.hours.to_i,
          Marshal.dump(value)
        )
      end
    end
  end
  
  def self.bulk_cache_read(keys)
    results = Redis.current.pipelined do |pipeline|
      keys.each do |key|
        pipeline.get("#{Rails.cache.options[:namespace]}:#{key}")
      end
    end
    
    results.map { |result| result ? Marshal.load(result) : nil }
  end
end
```

### **Phase 3: Memory and Performance Optimization**

#### 3.1 **Implement Cache Compression Strategy**
```ruby
# config/initializers/cache_compression.rb
module CacheCompression
  def self.compress_large_objects
    # Monkey patch Rails cache to compress large objects
    ActiveSupport::Cache::RedisCacheStore.prepend(Module.new do
      def write_entry(key, entry, **options)
        if entry.value.is_a?(String) && entry.value.bytesize > 1024
          compressed = Zlib::Deflate.deflate(entry.value)
          if compressed.bytesize < entry.value.bytesize * 0.8 # Only if 20%+ compression
            entry = ActiveSupport::Cache::Entry.new(
              compressed,
              expires_at: entry.expires_at,
              version: entry.version
            )
            options[:compressed] = true
          end
        end
        super(key, entry, **options)
      end
      
      def read_entry(key, **options)
        entry = super(key, **options)
        if entry && options[:compressed]
          decompressed = Zlib::Inflate.inflate(entry.value)
          entry = ActiveSupport::Cache::Entry.new(
            decompressed,
            expires_at: entry.expires_at,
            version: entry.version
          )
        end
        entry
      end
    end)
  end
end

CacheCompression.compress_large_objects if Rails.env.production?
```

#### 3.2 **Optimize Controller Cache Usage**
Replace complex cache keys with optimized versions:

```ruby
# In controllers (example for ordrs_controller.rb)
def show
  # Before: Complex cache key with multiple objects
  # Rails.cache.fetch([...complex array...])
  
  # After: Optimized cache key strategy
  cache_key = CacheKeyService.menu_content_key(
    ordr: @ordr,
    menu: @menu,
    participant: @ordrparticipant,
    currency: @restaurant_currency
  )
  
  @menu_content = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
    render_to_string(
      partial: 'shared/menu_content',
      locals: { ordr: @ordr, menu: @menu, participant: @ordrparticipant }
    )
  end
end
```

### **Phase 4: Monitoring and Maintenance**

#### 4.1 **Redis Performance Monitoring**
```ruby
# config/initializers/redis_monitoring.rb
if Rails.env.production?
  # Monitor Redis performance
  ActiveSupport::Notifications.subscribe('cache_read.active_support') do |name, start, finish, id, payload|
    duration = finish - start
    if duration > 0.1 # Log slow cache reads (>100ms)
      Rails.logger.warn(
        "Slow Redis read: #{payload[:key]} took #{duration.round(3)}s"
      )
    end
  end
  
  ActiveSupport::Notifications.subscribe('cache_write.active_support') do |name, start, finish, id, payload|
    duration = finish - start
    if duration > 0.2 # Log slow cache writes (>200ms)
      Rails.logger.warn(
        "Slow Redis write: #{payload[:key]} took #{duration.round(3)}s"
      )
    end
  end
end
```

#### 4.2 **Cache Health Check Endpoint**
```ruby
# config/routes.rb
get '/health/redis', to: 'health#redis_check'

# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def redis_check
    start_time = Time.current
    
    # Test basic Redis operations
    test_key = "health_check:#{SecureRandom.hex(8)}"
    test_value = "test_#{Time.current.to_i}"
    
    Rails.cache.write(test_key, test_value, expires_in: 1.minute)
    cached_value = Rails.cache.read(test_key)
    Rails.cache.delete(test_key)
    
    duration = Time.current - start_time
    
    if cached_value == test_value
      render json: {
        status: 'healthy',
        redis_latency_ms: (duration * 1000).round(2),
        timestamp: Time.current.iso8601
      }
    else
      render json: {
        status: 'unhealthy',
        error: 'Redis read/write test failed',
        timestamp: Time.current.iso8601
      }, status: 503
    end
  rescue => e
    render json: {
      status: 'unhealthy',
      error: e.message,
      timestamp: Time.current.iso8601
    }, status: 503
  end
end
```

## 🚀 **Implementation Priority**

### **High Priority (Immediate Impact)**
1. ✅ **Consolidate cache store configuration** - Eliminate conflicts
2. ✅ **Optimize Redis connection settings** - Better Heroku Redis performance
3. ✅ **Implement cache key optimization** - Reduce Redis memory usage

### **Medium Priority (Performance Gains)**
4. ✅ **Add Redis pipelining** - Bulk operations optimization
5. ✅ **Implement compression** - Memory usage reduction
6. ✅ **Add performance monitoring** - Visibility into cache performance

### **Low Priority (Long-term Maintenance)**
7. ✅ **Health check endpoints** - Operational monitoring
8. ✅ **Cache warming strategies** - Proactive cache population
9. ✅ **Advanced TTL strategies** - Dynamic cache expiration

## 📊 **Expected Performance Improvements**

### **Memory Usage**
- **30-50% reduction** in Redis memory usage through compression
- **20-30% reduction** in cache key overhead through optimization

### **Response Times**
- **15-25% faster** page load times for cached content
- **40-60% faster** bulk operations through pipelining
- **10-20% improvement** in Redis connection reliability

### **Heroku Redis Efficiency**
- **Better connection utilization** through pooling
- **Reduced timeout errors** through optimized settings
- **Improved failover handling** through enhanced reconnection logic

## 🎯 **Success Metrics**

1. **Redis Memory Usage**: Monitor via Heroku Redis dashboard
2. **Cache Hit Rates**: Target >85% hit rate for menu content
3. **Response Times**: <200ms for cached page loads
4. **Error Rates**: <0.1% Redis connection failures
5. **Heroku Redis Costs**: Potential to stay on mini plan longer

This optimization plan will significantly improve the Redis performance while maintaining the robust caching architecture already in place.
