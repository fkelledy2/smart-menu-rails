# frozen_string_literal: true

# Health check controller for monitoring system status
class HealthController < ApplicationController
  # Health endpoints are publicly accessible - no authentication required
  # All actions (index, redis_check, database_check, full_check, cache_stats) are public
  
  # Basic health check
  def index
    render json: {
      status: 'healthy',
      timestamp: Time.current.iso8601,
      version: Rails.application.class.module_parent_name,
      environment: Rails.env
    }
  end
  
  # Redis health check
  def redis_check
    start_time = Time.current
    
    begin
      # Test basic Redis operations
      test_key = "health_check:#{SecureRandom.hex(8)}"
      test_value = "test_#{Time.current.to_i}"
      
      # Test write
      Rails.cache.write(test_key, test_value, expires_in: 1.minute)
      
      # Test read
      cached_value = Rails.cache.read(test_key)
      
      # Test delete
      Rails.cache.delete(test_key)
      
      duration = Time.current - start_time
      
      if cached_value == test_value
        render json: {
          status: 'healthy',
          service: 'redis',
          latency_ms: (duration * 1000).round(2),
          cache_store: Rails.application.config.cache_store.first,
          namespace: Rails.cache.options[:namespace],
          timestamp: Time.current.iso8601
        }
      else
        render json: {
          status: 'unhealthy',
          service: 'redis',
          error: 'Redis read/write test failed - value mismatch',
          expected: test_value,
          actual: cached_value,
          timestamp: Time.current.iso8601
        }, status: 503
      end
      
    rescue => e
      render json: {
        status: 'unhealthy',
        service: 'redis',
        error: e.message,
        error_class: e.class.name,
        timestamp: Time.current.iso8601
      }, status: 503
    end
  end
  
  # Database health check
  def database_check
    start_time = Time.current
    
    begin
      # Test database connection
      ActiveRecord::Base.connection.execute('SELECT 1')
      
      # Test a simple query
      user_count = User.count
      
      duration = Time.current - start_time
      
      render json: {
        status: 'healthy',
        service: 'database',
        latency_ms: (duration * 1000).round(2),
        user_count: user_count,
        adapter: ActiveRecord::Base.connection.adapter_name,
        timestamp: Time.current.iso8601
      }
      
    rescue => e
      render json: {
        status: 'unhealthy',
        service: 'database',
        error: e.message,
        error_class: e.class.name,
        timestamp: Time.current.iso8601
      }, status: 503
    end
  end
  
  # Comprehensive health check
  def full_check
    results = {}
    overall_status = 'healthy'
    
    # Check Redis
    begin
      redis_start = Time.current
      test_key = "health_check:full:#{SecureRandom.hex(8)}"
      Rails.cache.write(test_key, 'test', expires_in: 1.minute)
      cached = Rails.cache.read(test_key)
      Rails.cache.delete(test_key)
      
      results[:redis] = {
        status: cached == 'test' ? 'healthy' : 'unhealthy',
        latency_ms: ((Time.current - redis_start) * 1000).round(2)
      }
      
      overall_status = 'unhealthy' if results[:redis][:status] == 'unhealthy'
      
    rescue => e
      results[:redis] = {
        status: 'unhealthy',
        error: e.message
      }
      overall_status = 'unhealthy'
    end
    
    # Check Database
    begin
      db_start = Time.current
      ActiveRecord::Base.connection.execute('SELECT 1')
      
      results[:database] = {
        status: 'healthy',
        latency_ms: ((Time.current - db_start) * 1000).round(2)
      }
      
    rescue => e
      results[:database] = {
        status: 'unhealthy',
        error: e.message
      }
      overall_status = 'unhealthy'
    end
    
    # Check IdentityCache
    begin
      ic_start = Time.current
      # Test IdentityCache if enabled
      if IdentityCache.respond_to?(:enabled?) && IdentityCache.enabled?
        # Try to fetch a simple record if any exist
        user = User.first
        if user
          User.fetch(user.id) # This will use IdentityCache
        end
      end
      
      results[:identity_cache] = {
        status: 'healthy',
        enabled: IdentityCache.respond_to?(:enabled?) ? IdentityCache.enabled? : 'unknown',
        latency_ms: ((Time.current - ic_start) * 1000).round(2)
      }
      
    rescue => e
      results[:identity_cache] = {
        status: 'degraded',
        error: e.message,
        enabled: false
      }
      # Don't mark overall as unhealthy for IdentityCache issues
    end
    
    status_code = overall_status == 'healthy' ? 200 : 503
    
    render json: {
      status: overall_status,
      timestamp: Time.current.iso8601,
      services: results,
      environment: Rails.env
    }, status: status_code
  end
  
  # Cache statistics (for monitoring)
  def cache_stats
    begin
      # Get Redis info if available
      redis_info = {}
      
      if Rails.cache.respond_to?(:redis)
        redis_client = Rails.cache.redis
        info = redis_client.info
        
        redis_info = {
          used_memory: info['used_memory_human'],
          connected_clients: info['connected_clients'],
          total_commands_processed: info['total_commands_processed'],
          keyspace_hits: info['keyspace_hits'],
          keyspace_misses: info['keyspace_misses'],
          hit_rate: calculate_hit_rate(info['keyspace_hits'], info['keyspace_misses'])
        }
      end
      
      render json: {
        status: 'healthy',
        cache_store: Rails.application.config.cache_store.first,
        namespace: Rails.cache.options[:namespace],
        redis_info: redis_info,
        identity_cache_enabled: IdentityCache.respond_to?(:enabled?) ? IdentityCache.enabled? : 'unknown',
        timestamp: Time.current.iso8601
      }
      
    rescue => e
      render json: {
        status: 'error',
        error: e.message,
        timestamp: Time.current.iso8601
      }, status: 503
    end
  end
  
  private
  
  def calculate_hit_rate(hits, misses)
    return 0 if hits.nil? || misses.nil?
    
    total = hits.to_i + misses.to_i
    return 0 if total == 0
    
    ((hits.to_f / total) * 100).round(2)
  end
end
