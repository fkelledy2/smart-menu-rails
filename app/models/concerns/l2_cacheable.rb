# frozen_string_literal: true

# Concern for adding L2 query caching capabilities to models
module L2Cacheable
  extend ActiveSupport::Concern

  class_methods do
    # Execute query with L2 caching
    # @param cache_key [String] Unique cache key
    # @param cache_type [Symbol] Type of cache (determines TTL)
    # @param force_refresh [Boolean] Force cache refresh
    # @param &block [Block] Block that returns an ActiveRecord::Relation
    # @return [ActiveRecord::Result] Query result
    def cached_query(cache_key, cache_type: :default, force_refresh: false, &block)
      relation = block.call
      sql = relation.to_sql
      
      # Extract bindings safely
      bindings = []
      if relation.respond_to?(:bound_attributes)
        bindings = relation.bound_attributes.map(&:value_before_type_cast)
      elsif relation.respond_to?(:bind_values)
        bindings = relation.bind_values
      end
      
      L2QueryCacheService.fetch_query(
        sql,
        bindings,
        cache_type: cache_type,
        force_refresh: force_refresh
      )
    end

    # Add L2 caching to a relation chain
    # @param cache_type [Symbol] Type of cache (determines TTL)
    # @param cache_key_suffix [String] Additional cache key suffix
    # @return [ActiveRecord::Relation] Relation with L2 caching
    def with_l2_cache(cache_type: :default, cache_key_suffix: nil)
      relation = all
      relation.extend(L2CacheableRelation)
      relation.instance_variable_set(:@l2_cache_type, cache_type)
      relation.instance_variable_set(:@l2_cache_key_suffix, cache_key_suffix)
      relation
    end

    # Cache complex aggregate queries
    # @param cache_key [String] Unique cache key
    # @param cache_type [Symbol] Type of cache
    # @param &block [Block] Block that returns aggregate value
    # @return [Object] Aggregate result
    def cached_aggregate(cache_key, cache_type: :aggregate, &block)
      full_key = "aggregate:#{table_name}:#{cache_key}"
      
      L2QueryCacheService.fetch_query(
        "SELECT #{cache_key}",
        [],
        cache_type: cache_type
      ) do
        block.call
      end
    rescue StandardError
      # Fallback to direct execution if caching fails
      block.call
    end

    # Clear L2 cache for this model
    def clear_l2_cache
      L2QueryCacheService.clear_pattern("*#{table_name}*")
    end
  end

  # Instance methods for L2 caching
  included do
    # Clear L2 cache after model changes
    after_commit :clear_model_l2_cache, on: [:create, :update, :destroy]
  end

  private

  # Clear L2 cache entries related to this model instance
  def clear_model_l2_cache
    # Clear caches that might include this record
    self.class.clear_l2_cache
    
    # Clear related caches if associations exist
    clear_association_caches if respond_to?(:clear_association_caches, true)
  end
end

# Module to extend ActiveRecord::Relation with L2 caching
module L2CacheableRelation
  # Override load to use L2 cache
  def load
    return super if loaded?
    
    cache_type = @l2_cache_type || :default
    cache_key_suffix = @l2_cache_key_suffix || ''
    
    # Generate cache key from SQL
    sql_hash = Digest::SHA256.hexdigest(to_sql)[0..15]
    cache_key = "relation:#{klass.table_name}:#{sql_hash}#{cache_key_suffix}"
    
    begin
      # Extract bindings safely
      bindings = []
      if respond_to?(:bound_attributes)
        bindings = bound_attributes.map(&:value_before_type_cast)
      elsif respond_to?(:bind_values)
        bindings = bind_values
      end
      
      result = L2QueryCacheService.fetch_query(
        to_sql,
        bindings,
        cache_type: cache_type
      )
      
      # Convert result to records
      @records = result.rows.map do |row|
        attributes = result.columns.zip(row).to_h
        klass.instantiate(attributes)
      end
      
      @loaded = true
      @records
    rescue StandardError => e
      Rails.logger.error "[L2Cacheable] Error loading with cache: #{e.message}"
      # Fallback to normal loading
      super
    end
  end

  # Force cache refresh
  def force_refresh
    @l2_force_refresh = true
    self
  end
end
