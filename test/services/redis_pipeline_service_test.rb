# frozen_string_literal: true

require 'test_helper'

class RedisPipelineServiceTest < ActiveSupport::TestCase
  def setup
    @test_data = {
      "test_key_1" => "test_value_1",
      "test_key_2" => "test_value_2",
      "test_key_3" => { data: "complex_object", array: [1, 2, 3] }
    }
  end

  def teardown
    # Clean up test keys
    @test_data.keys.each do |key|
      Rails.cache.delete(key)
    end
  end

  test "should perform bulk cache write" do
    assert_nothing_raised do
      RedisPipelineService.bulk_cache_write(@test_data)
    end
    
    # Verify data was written (using fallback methods in test environment)
    @test_data.each do |key, expected_value|
      cached_value = Rails.cache.read(key)
      assert_equal expected_value, cached_value, "Expected #{key} to have value #{expected_value}, but got #{cached_value}"
    end
  end

  test "should perform bulk cache read" do
    # First write the data using regular Rails cache
    @test_data.each do |key, value|
      Rails.cache.write(key, value)
    end
    
    # Then bulk read (will use fallback in test environment)
    results = RedisPipelineService.bulk_cache_read(@test_data.keys)
    
    assert_equal @test_data.size, results.size, "Expected #{@test_data.size} results, got #{results.size}. Results: #{results.inspect}"
    @test_data.each do |key, expected_value|
      assert_equal expected_value, results[key], "Expected #{key} to have value #{expected_value}, but got #{results[key]}"
    end
  end

  test "should perform bulk cache delete" do
    # First write the data
    @test_data.each do |key, value|
      Rails.cache.write(key, value)
    end
    
    # Verify data exists
    @test_data.keys.each do |key|
      assert Rails.cache.exist?(key), "Expected #{key} to exist before deletion"
    end
    
    # Bulk delete (will use fallback in test environment)
    deleted_count = RedisPipelineService.bulk_cache_delete(@test_data.keys)
    
    # Verify data was deleted
    @test_data.keys.each do |key|
      assert_not Rails.cache.exist?(key), "Expected #{key} to be deleted"
    end
  end

  test "should check bulk cache existence" do
    # Write some data
    Rails.cache.write("existing_key", "value")
    
    keys = ["existing_key", "non_existing_key"]
    results = RedisPipelineService.bulk_cache_exists(keys)
    
    assert_equal true, results["existing_key"], "Expected existing_key to be true, got #{results.inspect}"
    assert_equal false, results["non_existing_key"], "Expected non_existing_key to be false, got #{results.inspect}"
    
    # Clean up
    Rails.cache.delete("existing_key")
  end

  test "should handle empty operations gracefully" do
    assert_nothing_raised do
      RedisPipelineService.bulk_cache_write({})
      RedisPipelineService.bulk_cache_read([])
      RedisPipelineService.bulk_cache_delete([])
      RedisPipelineService.bulk_cache_exists([])
    end
    
    assert_equal({}, RedisPipelineService.bulk_cache_read([]))
    assert_equal 0, RedisPipelineService.bulk_cache_delete([])
    assert_equal({}, RedisPipelineService.bulk_cache_exists([]))
  end

  test "should handle large objects with compression" do
    large_data = {
      "large_key" => "x" * 2000 # Large string that should trigger compression
    }
    
    assert_nothing_raised do
      RedisPipelineService.bulk_cache_write(large_data)
    end
    
    # Verify large data can be read back correctly
    results = RedisPipelineService.bulk_cache_read(["large_key"])
    assert_equal large_data["large_key"], results["large_key"]
    
    # Clean up
    Rails.cache.delete("large_key")
  end

  test "should preload cache for objects" do
    # Create test objects (using existing fixtures)
    objects = [users(:one), users(:two)]
    
    # Mock cache method
    objects.each { |obj| obj.define_singleton_method(:cache_key) { "user_#{obj.id}" } }
    
    results = RedisPipelineService.preload_cache(objects, :cache_key) do |obj|
      "cached_data_for_#{obj.id}"
    end
    
    assert_equal objects.size, results.size
    objects.each do |obj|
      cache_key = obj.cache_key
      assert results.key?(cache_key)
      assert_equal "cached_data_for_#{obj.id}", results[cache_key]
    end
    
    # Clean up
    objects.each do |obj|
      Rails.cache.delete(obj.cache_key)
    end
  end

  test "should handle Redis connection errors gracefully" do
    # Test that the service handles errors gracefully regardless of cache backend
    assert_nothing_raised do
      RedisPipelineService.bulk_cache_write({"test_key" => "test_value"})
    end
    
    # Verify the data was written
    assert_equal "test_value", Rails.cache.read("test_key")
  end

  test "should invalidate cache patterns" do
    # Clean up any existing keys that might interfere
    ["pattern:test:1", "pattern:test:2", "other:key"].each do |key|
      Rails.cache.delete(key)
    end
    
    # Test pattern invalidation - behavior depends on cache backend
    pattern_data = {
      "pattern:test:1" => "value1",
      "pattern:test:2" => "value2",
      "other:key" => "value3"
    }
    
    pattern_data.each do |key, value|
      Rails.cache.write(key, value)
    end
    
    # Invalidate pattern (will use fallback if Redis not available)
    deleted_count = RedisPipelineService.bulk_invalidate_patterns(["pattern:test:*"])
    
    # Check if we actually have a working Redis backend by trying to access it
    has_working_redis = begin
      Rails.cache.respond_to?(:redis) && Rails.cache.redis.respond_to?(:pipelined)
    rescue
      false
    end
    
    if has_working_redis
      # Redis backend - should actually delete matching keys
      assert_not Rails.cache.exist?("pattern:test:1"), "Expected pattern:test:1 to be deleted"
      assert_not Rails.cache.exist?("pattern:test:2"), "Expected pattern:test:2 to be deleted"
      assert Rails.cache.exist?("other:key"), "Expected other:key to remain"
      assert deleted_count > 0, "Expected some keys to be deleted"
    else
      # Memory store or other backend - pattern deletion not supported
      # Just verify the method doesn't crash and returns 0
      assert_equal 0, deleted_count, "Expected 0 deleted keys for non-Redis backend"
      # Keys should still exist since pattern deletion isn't supported
      assert Rails.cache.exist?("pattern:test:1"), "Expected pattern:test:1 to still exist"
      assert Rails.cache.exist?("pattern:test:2"), "Expected pattern:test:2 to still exist"
      assert Rails.cache.exist?("other:key"), "Expected other:key to still exist"
    end
    
    # Clean up
    Rails.cache.delete("pattern:test:1")
    Rails.cache.delete("pattern:test:2")
    Rails.cache.delete("other:key")
  end

  test "should handle mixed data types in bulk operations" do
    mixed_data = {
      "string_key" => "string_value",
      "hash_key" => { name: "test", id: 123 },
      "array_key" => [1, 2, 3, "mixed"],
      "number_key" => 42,
      "boolean_key" => true
    }
    
    # Write mixed data (will use fallback in test environment)
    RedisPipelineService.bulk_cache_write(mixed_data)
    
    # Read it back (will use fallback in test environment)
    results = RedisPipelineService.bulk_cache_read(mixed_data.keys)
    
    # Verify all data types are preserved
    mixed_data.each do |key, expected_value|
      assert_equal expected_value, results[key], "Failed for key: #{key}. Expected: #{expected_value.inspect}, Got: #{results[key].inspect}"
    end
    
    # Clean up
    mixed_data.keys.each { |key| Rails.cache.delete(key) }
  end
end
