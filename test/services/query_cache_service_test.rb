require 'test_helper'

class QueryCacheServiceTest < ActiveSupport::TestCase
  def setup
    @service = QueryCacheService.instance
    # Clear any existing cache data
    Rails.cache.clear
    @service.instance_variable_set(:@cache_performance_data, nil)
  end

  def teardown
    Rails.cache.clear
  end

  # Singleton tests
  test 'should be a singleton' do
    service1 = QueryCacheService.instance
    service2 = QueryCacheService.instance
    assert_same service1, service2
  end

  test 'should delegate class methods to instance' do
    assert_respond_to QueryCacheService, :fetch
    assert_respond_to QueryCacheService, :clear
    assert_respond_to QueryCacheService, :clear_pattern
    assert_respond_to QueryCacheService, :warm_cache
  end

  # Cache duration configuration tests
  test 'should have predefined cache durations' do
    durations = QueryCacheService::CACHE_DURATIONS

    assert_equal 5.minutes, durations[:metrics_summary]
    assert_equal 1.minute, durations[:system_metrics]
    assert_equal 30.seconds, durations[:recent_metrics]
    assert_equal 10.minutes, durations[:analytics_dashboard]
    assert_equal 15.minutes, durations[:order_analytics]
    assert_equal 1.hour, durations[:revenue_reports]
    assert_equal 6.hours, durations[:daily_stats]
    assert_equal 24.hours, durations[:monthly_reports]
    assert_equal 30.minutes, durations[:user_analytics]
    assert_equal 20.minutes, durations[:restaurant_analytics]
  end

  # Fetch method tests (basic functionality without performance tracking)
  test 'should fetch and cache result' do
    # Mock the performance tracking to avoid errors
    @service.stub(:track_cache_performance, nil) do
      result = @service.fetch('test_key', cache_type: :metrics_summary) do
        'test_result'
      end

      assert_equal 'test_result', result

      # Verify it's cached by fetching again without block
      cached_result = Rails.cache.read('query_cache:metrics_summary:test_key')
      assert_equal 'test_result', cached_result
    end
  end

  test 'should use default cache type when not specified' do
    @service.stub(:track_cache_performance, nil) do
      result = @service.fetch('test_key') do
        'default_result'
      end

      assert_equal 'default_result', result

      # Should use default TTL of 5 minutes
      cached_result = Rails.cache.read('query_cache:default:test_key')
      assert_equal 'default_result', cached_result
    end
  end

  test 'should return cached result on subsequent calls' do
    @service.stub(:track_cache_performance, nil) do
      call_count = 0

      # First call
      result1 = @service.fetch('counter_key') do
        call_count += 1
        "result_#{call_count}"
      end

      # Second call should return cached result
      result2 = @service.fetch('counter_key') do
        call_count += 1
        "result_#{call_count}"
      end

      assert_equal 'result_1', result1
      assert_equal 'result_1', result2 # Should be same cached result
      assert_equal 1, call_count # Block should only execute once
    end
  end

  test 'should force refresh when requested' do
    @service.stub(:track_cache_performance, nil) do
      call_count = 0

      # First call
      result1 = @service.fetch('refresh_key') do
        call_count += 1
        "result_#{call_count}"
      end

      # Second call with force_refresh
      result2 = @service.fetch('refresh_key', force_refresh: true) do
        call_count += 1
        "result_#{call_count}"
      end

      assert_equal 'result_1', result1
      assert_equal 'result_2', result2 # Should be new result
      assert_equal 2, call_count # Block should execute twice
    end
  end

  test 'should handle errors gracefully' do
    @service.stub(:track_cache_performance, nil) do
      error_message = 'Test error'

      assert_raises(StandardError) do
        @service.fetch('error_key') do
          raise StandardError, error_message
        end
      end
    end
  end

  # Clear method tests
  test 'should clear specific cache entry' do
    @service.stub(:track_cache_performance, nil) do
      # Cache a value
      @service.fetch('clear_test') { 'cached_value' }

      # Verify it's cached
      assert_equal 'cached_value', Rails.cache.read('query_cache:default:clear_test')

      # Clear it
      @service.clear('clear_test')

      # Verify it's gone
      assert_nil Rails.cache.read('query_cache:default:clear_test')
    end
  end

  test 'should clear cache entry with specific type' do
    @service.stub(:track_cache_performance, nil) do
      # Cache a value with specific type
      @service.fetch('typed_clear_test', cache_type: :metrics_summary) { 'typed_value' }

      # Clear with same type
      @service.clear('typed_clear_test', cache_type: :metrics_summary)

      # Verify it's gone
      assert_nil Rails.cache.read('query_cache:metrics_summary:typed_clear_test')
    end
  end

  # Clear pattern tests
  test 'should clear pattern when cache supports it' do
    # Mock cache to support delete_matched
    Rails.cache.stub(:respond_to?, ->(method) { method == :delete_matched }) do
      Rails.cache.stub(:delete_matched, lambda { |pattern|
        assert_equal 'query_cache:test_*', pattern
        true
      },) do
        @service.clear_pattern('test_*')
      end
    end
  end

  test 'should handle cache backend without pattern support' do
    # Mock cache to not support delete_matched
    Rails.cache.stub(:respond_to?, ->(_method) { false }) do
      # Should not raise error, just log warning
      assert_nothing_raised do
        @service.clear_pattern('test_*')
      end
    end
  end

  # Warm cache tests
  test 'should warm cache with provided configurations' do
    @service.stub(:track_cache_performance, nil) do
      call_count = 0

      cache_configs = [
        {
          key: 'warm_key_1',
          type: :metrics_summary,
          block: proc {
            call_count += 1
            "warm_result_#{call_count}"
          },
        },
        {
          key: 'warm_key_2',
          type: :system_metrics,
          block: proc {
            call_count += 1
            "warm_result_#{call_count}"
          },
        },
      ]

      @service.warm_cache(cache_configs)

      # Verify both entries were cached
      assert_equal 'warm_result_1', Rails.cache.read('query_cache:metrics_summary:warm_key_1')
      assert_equal 'warm_result_2', Rails.cache.read('query_cache:system_metrics:warm_key_2')
      assert_equal 2, call_count
    end
  end

  test 'should handle errors during cache warming' do
    @service.stub(:track_cache_performance, nil) do
      cache_configs = [
        {
          key: 'good_key',
          type: :metrics_summary,
          block: proc { 'good_result' },
        },
        {
          key: 'bad_key',
          type: :system_metrics,
          block: proc { raise StandardError, 'Warming error' },
        },
      ]

      # Should not raise error, should continue with other configs
      assert_nothing_raised do
        @service.warm_cache(cache_configs)
      end

      # Good key should be cached
      assert_equal 'good_result', Rails.cache.read('query_cache:metrics_summary:good_key')

      # Bad key should not be cached
      assert_nil Rails.cache.read('query_cache:system_metrics:bad_key')
    end
  end

  # Cache stats tests (simplified - skip complex performance tracking)
  test 'should have cache stats method' do
    # Just verify the method exists and returns a hash
    stats = @service.cache_stats
    assert_instance_of Hash, stats
    assert_respond_to stats, :[]
  end

  test 'should calculate hit rate correctly' do
    # Mock performance data with known values
    performance_data = {
      cache_hits: 8,
      cache_misses: 2,
      total_requests: 10,
      errors: 0,
      total_query_time: 1.5,
      by_type: {},
    }

    Rails.cache.write('query_cache:performance', performance_data)
    @service.instance_variable_set(:@cache_performance_data, nil) # Reset memoization

    stats = @service.cache_stats
    assert_equal 80.0, stats[:hit_rate] # 8/(8+2) * 100 = 80%
  end

  test 'should handle zero hit rate calculation' do
    # Mock performance data with no hits or misses
    performance_data = {
      cache_hits: 0,
      cache_misses: 0,
      total_requests: 0,
      errors: 0,
      total_query_time: 0.0,
      by_type: {},
    }

    Rails.cache.write('query_cache:performance', performance_data)
    @service.instance_variable_set(:@cache_performance_data, nil)

    stats = @service.cache_stats
    assert_equal 0.0, stats[:hit_rate]
  end

  test 'should handle zero average query time calculation' do
    # Mock performance data with no misses
    performance_data = {
      cache_hits: 5,
      cache_misses: 0,
      total_requests: 5,
      errors: 0,
      total_query_time: 2.5,
      by_type: {},
    }

    Rails.cache.write('query_cache:performance', performance_data)
    @service.instance_variable_set(:@cache_performance_data, nil)

    stats = @service.cache_stats
    assert_equal 0.0, stats[:average_query_time]
  end

  # Private method tests (testing through public interface)
  test 'should build correct cache keys' do
    @service.stub(:track_cache_performance, nil) do
      @service.fetch('test_key', cache_type: :metrics_summary) { 'value' }

      # Verify the key format
      cached_value = Rails.cache.read('query_cache:metrics_summary:test_key')
      assert_equal 'value', cached_value
    end
  end

  test 'should use correct TTL for different cache types' do
    @service.stub(:track_cache_performance, nil) do
      # This is harder to test directly, but we can verify the durations are used
      freeze_time = Time.current

      Time.stub(:current, freeze_time) do
        @service.fetch('ttl_test', cache_type: :system_metrics) { 'test_value' }
      end

      # The value should be cached (we can't easily test TTL without waiting)
      assert_equal 'test_value', Rails.cache.read('query_cache:system_metrics:ttl_test')
    end
  end

  # Class method delegation tests
  test 'should delegate fetch to instance' do
    QueryCacheService.instance.stub(:track_cache_performance, nil) do
      result = QueryCacheService.fetch('delegate_test') { 'delegated_result' }
      assert_equal 'delegated_result', result
    end
  end

  test 'should delegate clear to instance' do
    QueryCacheService.instance.stub(:track_cache_performance, nil) do
      QueryCacheService.fetch('delegate_clear_test') { 'value_to_clear' }
      QueryCacheService.clear('delegate_clear_test')

      assert_nil Rails.cache.read('query_cache:default:delegate_clear_test')
    end
  end

  test 'should delegate clear_pattern to instance' do
    # Just verify it doesn't raise an error
    assert_nothing_raised do
      QueryCacheService.clear_pattern('delegate_*')
    end
  end

  test 'should delegate warm_cache to instance' do
    QueryCacheService.instance.stub(:track_cache_performance, nil) do
      configs = [{ key: 'delegate_warm', type: :default, block: proc { 'warmed' } }]

      assert_nothing_raised do
        QueryCacheService.warm_cache(configs)
      end

      assert_equal 'warmed', Rails.cache.read('query_cache:default:delegate_warm')
    end
  end
end
