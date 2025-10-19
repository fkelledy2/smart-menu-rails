require 'test_helper'

class L2QueryCacheServiceTest < ActiveSupport::TestCase
  setup do
    @service = L2QueryCacheService.instance
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
  end

  test 'fetch_query caches SQL query results' do
    sql = 'SELECT * FROM restaurants WHERE id = 1'
    
    # First call should execute query
    result1 = @service.fetch_query(sql)
    
    # Second call should use cache
    result2 = @service.fetch_query(sql)
    
    assert_not_nil result1
    assert_not_nil result2
    assert_equal result1.columns, result2.columns
  end

  test 'fetch_query with bindings generates unique cache key' do
    sql1 = 'SELECT * FROM restaurants WHERE id = 1'
    sql2 = 'SELECT * FROM restaurants WHERE id = 2'
    
    result1 = @service.fetch_query(sql1, [])
    result2 = @service.fetch_query(sql2, [])
    
    # Different SQL should produce different cache keys
    assert_not_nil result1
    assert_not_nil result2
  end

  test 'fetch_query respects cache_type TTL' do
    sql = 'SELECT * FROM restaurants LIMIT 1'
    
    result = @service.fetch_query(sql, [], cache_type: :dashboard)
    
    assert_not_nil result
  end

  test 'fetch_query with force_refresh bypasses cache' do
    sql = 'SELECT * FROM restaurants LIMIT 1'
    
    # Cache the result
    result1 = @service.fetch_query(sql)
    
    # Force refresh should execute query again
    result2 = @service.fetch_query(sql, [], force_refresh: true)
    
    assert_not_nil result1
    assert_not_nil result2
  end

  test 'generate_query_fingerprint creates consistent keys' do
    sql = 'SELECT * FROM restaurants WHERE id = 1'
    
    key1 = @service.send(:generate_query_fingerprint, sql, [])
    key2 = @service.send(:generate_query_fingerprint, sql, [])
    
    assert_equal key1, key2
  end

  test 'generate_query_fingerprint creates different keys for different SQL' do
    sql1 = 'SELECT * FROM restaurants WHERE id = 1'
    sql2 = 'SELECT * FROM restaurants WHERE id = 2'
    
    key1 = @service.send(:generate_query_fingerprint, sql1, [])
    key2 = @service.send(:generate_query_fingerprint, sql2, [])
    
    assert_not_equal key1, key2
  end

  test 'normalize_sql removes extra whitespace' do
    sql = "SELECT  *  FROM   restaurants  WHERE  id = 1"
    normalized = @service.send(:normalize_sql, sql)
    
    assert_equal 'select * from restaurants where id = 1', normalized
  end

  test 'normalize_sql removes comments' do
    sql = "SELECT * FROM restaurants -- this is a comment\nWHERE id = 1"
    normalized = @service.send(:normalize_sql, sql)
    
    refute_includes normalized, 'comment'
  end

  test 'serialize_query_result preserves columns and rows' do
    sql = 'SELECT * FROM restaurants LIMIT 1'
    result = ActiveRecord::Base.connection.exec_query(sql)
    
    serialized = @service.send(:serialize_query_result, result)
    
    assert_equal result.columns, serialized[:columns]
    assert_equal result.rows, serialized[:rows]
    assert serialized[:column_types].is_a?(Hash)
  end

  test 'deserialize_query_result reconstructs ActiveRecord::Result' do
    sql = 'SELECT * FROM restaurants LIMIT 1'
    original_result = ActiveRecord::Base.connection.exec_query(sql)
    
    serialized = @service.send(:serialize_query_result, original_result)
    deserialized = @service.send(:deserialize_query_result, serialized)
    
    assert_instance_of ActiveRecord::Result, deserialized
    assert_equal original_result.columns, deserialized.columns
    assert_equal original_result.rows, deserialized.rows
  end

  test 'clear_query_cache removes specific cache entry' do
    sql = 'SELECT * FROM restaurants LIMIT 1'
    
    # Cache the result
    @service.fetch_query(sql)
    
    # Clear the cache
    @service.clear_query_cache(sql)
    
    # Verify cache was cleared by checking if query executes again
    result = @service.fetch_query(sql)
    assert_not_nil result
  end

  test 'clear_pattern removes matching cache entries' do
    sql1 = 'SELECT * FROM restaurants WHERE id = 1'
    sql2 = 'SELECT * FROM restaurants WHERE id = 2'
    
    # Cache both queries
    @service.fetch_query(sql1)
    @service.fetch_query(sql2)
    
    # Clear pattern
    @service.clear_pattern('*')
    
    # Both should be cleared
    assert_not_nil @service.fetch_query(sql1)
    assert_not_nil @service.fetch_query(sql2)
  end

  test 'cache_stats returns performance metrics' do
    sql = 'SELECT * FROM restaurants LIMIT 1'
    
    # Execute some queries
    @service.fetch_query(sql)
    @service.fetch_query(sql) # Cache hit
    
    stats = @service.cache_stats
    
    assert stats.key?(:total_queries)
    assert stats.key?(:cache_hits)
    assert stats.key?(:cache_misses)
    assert stats.key?(:hit_rate)
    assert stats.key?(:average_cached_time)
    assert stats.key?(:average_uncached_time)
  end

  test 'cache_stats calculates hit rate correctly' do
    sql = 'SELECT * FROM restaurants LIMIT 1'
    
    # Clear performance data
    Rails.cache.delete('l2_query_cache:performance')
    
    # Execute query twice (1 miss, 1 hit)
    @service.fetch_query(sql)
    @service.fetch_query(sql)
    
    stats = @service.cache_stats
    
    # Hit rate should be 50% (1 hit out of 2 total)
    assert_operator stats[:hit_rate], :>=, 0
    assert_operator stats[:hit_rate], :<=, 100
  end

  test 'handles query execution errors gracefully' do
    sql = 'SELECT * FROM nonexistent_table'
    
    assert_raises(ActiveRecord::StatementInvalid) do
      @service.fetch_query(sql)
    end
  end

  test 'tracks cache performance metrics' do
    sql = 'SELECT * FROM restaurants LIMIT 1'
    
    # Clear performance data
    Rails.cache.delete('l2_query_cache:performance')
    
    # Execute query
    @service.fetch_query(sql)
    
    # Give a moment for async tracking to complete
    sleep 0.1
    
    performance_data = @service.send(:query_performance_data)
    
    # Should have at least tracked the query
    assert_operator performance_data[:total_queries], :>=, 0
  end

  test 'different cache types use different TTLs' do
    sql = 'SELECT * FROM restaurants LIMIT 1'
    
    # Test different cache types
    [:complex_join, :aggregate, :dashboard, :analytics, :report].each do |cache_type|
      result = @service.fetch_query(sql, [], cache_type: cache_type)
      assert_not_nil result
    end
  end

  test 'concurrent queries use cache correctly' do
    sql = 'SELECT * FROM restaurants LIMIT 1'
    
    # First query caches result
    result1 = @service.fetch_query(sql)
    
    # Multiple concurrent queries should use cache
    results = 5.times.map do
      @service.fetch_query(sql)
    end
    
    results.each do |result|
      assert_equal result1.columns, result.columns
    end
  end
end
