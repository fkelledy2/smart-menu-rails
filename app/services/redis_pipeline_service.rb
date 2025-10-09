# frozen_string_literal: true

# Service for Redis pipelining operations to improve bulk performance
class RedisPipelineService
  class << self
    # Bulk cache write using Redis pipelining
    def bulk_cache_write(data_hash, expires_in: 6.hours)
      return [] if data_hash.empty?
      
      # Check if Redis is available and supports pipelining
      unless redis_available?
        return fallback_bulk_write(data_hash, expires_in)
      end
      
      namespace = Rails.cache.options[:namespace] || ""
      expiry_seconds = expires_in.to_i
      
      results = nil
      
      # Use Redis pipelining for bulk operations
      Rails.cache.redis.pipelined do |pipeline|
        data_hash.each do |key, value|
          namespaced_key = namespace.empty? ? key : "#{namespace}:#{key}"
          serialized_value = Marshal.dump(value)
          
          # Compress large values
          if serialized_value.bytesize > 1024
            compressed = Zlib::Deflate.deflate(serialized_value)
            if compressed.bytesize < serialized_value.bytesize * 0.8
              serialized_value = compressed
              pipeline.hset(namespaced_key, 'compressed', '1')
            end
          end
          
          pipeline.setex(namespaced_key, expiry_seconds, serialized_value)
        end
      end
      
      Rails.logger.debug("[RedisPipelineService] Bulk wrote #{data_hash.size} entries")
      results
      
    rescue => e
      Rails.logger.error("[RedisPipelineService] Bulk write failed: #{e.message}")
      # Fallback to individual writes
      fallback_bulk_write(data_hash, expires_in)
    end
    
    # Bulk cache read using Redis pipelining
    def bulk_cache_read(keys)
      return {} if keys.empty?
      
      # Check if Redis is available and supports pipelining
      unless redis_available?
        return fallback_bulk_read(keys)
      end
      
      namespace = Rails.cache.options[:namespace] || ""
      results = {}
      
      # Use Redis pipelining for bulk reads
      redis_results = Rails.cache.redis.pipelined do |pipeline|
        keys.each do |key|
          namespaced_key = namespace.empty? ? key : "#{namespace}:#{key}"
          pipeline.get(namespaced_key)
        end
      end
      
      # Process results
      keys.each_with_index do |key, index|
        redis_value = redis_results[index]
        next unless redis_value
        
        begin
          # Check if value was compressed
          namespaced_key = namespace.empty? ? key : "#{namespace}:#{key}"
          compressed_flag = Rails.cache.redis.hget(namespaced_key, 'compressed')
          
          if compressed_flag == '1'
            decompressed = Zlib::Inflate.inflate(redis_value)
            results[key] = Marshal.load(decompressed)
          else
            results[key] = Marshal.load(redis_value)
          end
        rescue => e
          Rails.logger.warn("[RedisPipelineService] Failed to deserialize key #{key}: #{e.message}")
        end
      end
      
      Rails.logger.debug("[RedisPipelineService] Bulk read #{results.size}/#{keys.size} entries")
      results
      
    rescue => e
      Rails.logger.error("[RedisPipelineService] Bulk read failed: #{e.message}")
      # Fallback to individual reads
      fallback_bulk_read(keys)
    end
    
    # Bulk cache delete using Redis pipelining
    def bulk_cache_delete(keys)
      return 0 if keys.empty?
      
      namespace = Rails.cache.options[:namespace]
      
      deleted_count = Rails.cache.redis.pipelined do |pipeline|
        keys.each do |key|
          namespaced_key = "#{namespace}:#{key}"
          pipeline.del(namespaced_key)
          # Also delete compression metadata if it exists
          pipeline.del("#{namespaced_key}:meta")
        end
      end.sum
      
      Rails.logger.debug("[RedisPipelineService] Bulk deleted #{deleted_count} entries")
      deleted_count
      
    rescue => e
      Rails.logger.error("[RedisPipelineService] Bulk delete failed: #{e.message}")
      # Fallback to individual deletes
      fallback_bulk_delete(keys)
    end
    
    # Bulk cache existence check
    def bulk_cache_exists(keys)
      return {} if keys.empty?
      
      namespace = Rails.cache.options[:namespace]
      results = {}
      
      existence_results = Rails.cache.redis.pipelined do |pipeline|
        keys.each do |key|
          namespaced_key = "#{namespace}:#{key}"
          pipeline.exists?(namespaced_key)
        end
      end
      
      keys.each_with_index do |key, index|
        results[key] = existence_results[index] > 0
      end
      
      results
      
    rescue => e
      Rails.logger.error("[RedisPipelineService] Bulk exists check failed: #{e.message}")
      # Fallback to individual checks
      keys.each_with_object({}) do |key, hash|
        hash[key] = Rails.cache.exist?(key)
      end
    end
    
    # Batch invalidate cache patterns
    def bulk_invalidate_patterns(patterns)
      return 0 if patterns.empty?
      
      # Check if Redis is available and supports pattern operations
      unless redis_available?
        Rails.logger.debug("[RedisPipelineService] Redis not available, pattern invalidation not supported")
        return 0
      end
      
      total_deleted = 0
      
      patterns.each do |pattern|
        # Get all keys matching pattern
        matching_keys = Rails.cache.redis.keys("#{Rails.cache.options[:namespace]}:#{pattern}")
        
        if matching_keys.any?
          # Delete in batches to avoid blocking Redis
          matching_keys.each_slice(100) do |key_batch|
            deleted = Rails.cache.redis.pipelined do |pipeline|
              key_batch.each { |key| pipeline.del(key) }
            end.sum
            
            total_deleted += deleted
          end
        end
      end
      
      Rails.logger.info("[RedisPipelineService] Bulk invalidated #{total_deleted} keys across #{patterns.size} patterns")
      total_deleted
      
    rescue => e
      Rails.logger.error("[RedisPipelineService] Bulk invalidation failed: #{e.message}")
      0
    end
    
    # Preload cache for multiple objects
    def preload_cache(objects, cache_method)
      return {} if objects.empty?
      
      cache_keys = objects.map { |obj| obj.send(cache_method) }
      existing_cache = bulk_cache_read(cache_keys)
      
      # Identify missing cache entries
      missing_objects = objects.reject { |obj| existing_cache.key?(obj.send(cache_method)) }
      
      # Generate missing cache entries
      if missing_objects.any?
        new_cache_data = {}
        missing_objects.each do |obj|
          cache_key = obj.send(cache_method)
          new_cache_data[cache_key] = yield(obj) if block_given?
        end
        
        # Bulk write new cache entries
        bulk_cache_write(new_cache_data) if new_cache_data.any?
        existing_cache.merge!(new_cache_data)
      end
      
      existing_cache
    end
    
    private
    
    # Check if Redis is available for pipelining
    def redis_available?
      Rails.cache.respond_to?(:redis) && Rails.cache.redis.respond_to?(:pipelined)
    rescue => e
      Rails.logger.debug("[RedisPipelineService] Redis not available: #{e.message}")
      false
    end
    
    # Fallback methods for when pipelining fails
    def fallback_bulk_write(data_hash, expires_in)
      data_hash.each do |key, value|
        Rails.cache.write(key, value, expires_in: expires_in)
      end
    end
    
    def fallback_bulk_read(keys)
      keys.each_with_object({}) do |key, results|
        value = Rails.cache.read(key)
        results[key] = value unless value.nil?
      end
    end
    
    def fallback_bulk_delete(keys)
      keys.map { |key| Rails.cache.delete(key) ? 1 : 0 }.sum
    end
  end
end
