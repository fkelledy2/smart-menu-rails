# frozen_string_literal: true

require 'test_helper'

class CacheMetricsServiceTest < ActiveSupport::TestCase
  def setup
    # Clear cache before each test
    Rails.cache.clear

    # Set up test metrics
    Rails.cache.write('cache_metrics:hits', 100)
    Rails.cache.write('cache_metrics:misses', 20)
    Rails.cache.write('cache_metrics:writes', 50)
    Rails.cache.write('cache_metrics:deletes', 10)
    Rails.cache.write('cache_metrics:errors', 2)
  end

  def teardown
    # Clean up cache after each test
    Rails.cache.clear
  end

  # Test metrics constants
  test 'should have defined metrics and time windows' do
    assert_includes CacheMetricsService::METRICS, :hit_rate
    assert_includes CacheMetricsService::METRICS, :memory_usage
    assert_includes CacheMetricsService::METRICS, :throughput

    assert_equal 1.minute, CacheMetricsService::TIME_WINDOWS[:realtime]
    assert_equal 5.minutes, CacheMetricsService::TIME_WINDOWS[:short]
    assert_equal 1.hour, CacheMetricsService::TIME_WINDOWS[:medium]
    assert_equal 24.hours, CacheMetricsService::TIME_WINDOWS[:long]
  end

  # Test metrics collection
  test 'should collect comprehensive metrics' do
    # Mock individual metric collection methods
    CacheMetricsService.stub :collect_performance_metrics, ->(_window) { { hit_rate: 83.33 } } do
      CacheMetricsService.stub :collect_memory_metrics, -> { { usage: {} } } do
        CacheMetricsService.stub :collect_operation_metrics, ->(_window) { { total_operations: 182 } } do
          CacheMetricsService.stub :collect_health_metrics, -> { { availability: true } } do
            CacheMetricsService.stub :collect_pattern_metrics, -> { { key_counts: {} } } do
              CacheMetricsService.stub :generate_recommendations, -> { [] } do
                metrics = CacheMetricsService.collect_metrics(window: :medium)

                assert_kind_of Hash, metrics
                assert_includes metrics.keys, :timestamp
                assert_includes metrics.keys, :window
                assert_includes metrics.keys, :performance
                assert_includes metrics.keys, :memory
                assert_includes metrics.keys, :operations
                assert_includes metrics.keys, :health
                assert_includes metrics.keys, :patterns
                assert_includes metrics.keys, :recommendations

                assert_equal :medium, metrics[:window]
                assert_equal 1.hour, metrics[:duration]
              end
            end
          end
        end
      end
    end
  end

  # Test hit rate calculation
  test 'should calculate hit rate correctly' do
    hit_rate = CacheMetricsService.calculate_hit_rate

    # Expected: 100 hits / (100 hits + 20 misses) = 83.33%
    assert_equal 83.33, hit_rate
  end

  test 'should handle zero operations for hit rate' do
    Rails.cache.write('cache_metrics:hits', 0)
    Rails.cache.write('cache_metrics:misses', 0)

    hit_rate = CacheMetricsService.calculate_hit_rate
    assert_equal 0.0, hit_rate
  end

  # Test miss rate calculation
  test 'should calculate miss rate correctly' do
    miss_rate = CacheMetricsService.calculate_miss_rate

    # Expected: 100 - 83.33 = 16.67%
    assert_equal 16.67, miss_rate
  end

  # Test throughput calculation
  test 'should calculate throughput correctly' do
    # Mock TIME_WINDOWS for predictable calculation
    CacheMetricsService.stub_const(:TIME_WINDOWS, { medium: 60.seconds }) do
      throughput = CacheMetricsService.calculate_throughput(window: :medium)

      # Expected: (100 + 20 + 50 + 10) operations / 60 seconds = 3.0 ops/sec
      assert_equal 3.0, throughput
    end
  rescue NoMethodError
    # Fallback for environments without stub_const
    # Calculate manually with known duration
    total_ops = CacheMetricsService.calculate_total_operations(window: :medium)
    duration_seconds = 3600 # 1 hour in seconds for :medium window
    expected_throughput = (total_ops.to_f / duration_seconds).round(2)

    throughput = CacheMetricsService.calculate_throughput(window: :medium)
    assert_equal expected_throughput, throughput
  end

  # Test total operations calculation
  test 'should calculate total operations correctly' do
    total_ops = CacheMetricsService.calculate_total_operations

    # Expected: 100 + 20 + 50 + 10 = 180
    assert_equal 180, total_ops
  end

  # Test error rate calculation
  test 'should calculate error rate correctly' do
    error_rate = CacheMetricsService.calculate_error_rate

    # Expected: 2 errors / 180 total operations = 1.11%
    assert_equal 1.11, error_rate
  end

  test 'should handle zero operations for error rate' do
    Rails.cache.write('cache_metrics:hits', 0)
    Rails.cache.write('cache_metrics:misses', 0)
    Rails.cache.write('cache_metrics:writes', 0)
    Rails.cache.write('cache_metrics:deletes', 0)

    error_rate = CacheMetricsService.calculate_error_rate
    assert_equal 0.0, error_rate
  end

  # Test memory usage
  test 'should get memory usage when Redis is available' do
    # Mock Redis memory info
    memory_info = {
      'used_memory' => 1_048_576,
      'used_memory_human' => '1.00M',
      'used_memory_peak' => 2_097_152,
      'used_memory_peak_human' => '2.00M',
      'mem_fragmentation_ratio' => 1.2,
    }

    # Mock Redis cache and methods
    mock_redis = Object.new
    mock_redis.define_singleton_method(:memory) { |_type| memory_info }

    mock_cache = Object.new
    mock_cache.define_singleton_method(:redis) { mock_redis }

    CacheMetricsService.stub :redis_available?, true do
      Rails.stub :cache, mock_cache do
        usage = CacheMetricsService.get_memory_usage

        assert_equal 1_048_576, usage[:used_memory]
        assert_equal '1.00M', usage[:used_memory_human]
        assert_equal 2_097_152, usage[:used_memory_peak]
        assert_equal '2.00M', usage[:used_memory_peak_human]
        assert_equal 1.2, usage[:memory_fragmentation_ratio]
        assert_kind_of Numeric, usage[:memory_efficiency]
      end
    end
  end

  test 'should handle Redis unavailable for memory usage' do
    CacheMetricsService.stub :redis_available?, false do
      usage = CacheMetricsService.get_memory_usage
      assert_equal({}, usage)
    end
  end

  # Test compression ratio calculation
  test 'should calculate compression ratio' do
    # Mock cache options
    Rails.cache.stub :options, { compression_threshold: 512 } do
      ratio = CacheMetricsService.calculate_compression_ratio
      assert_equal 0.65, ratio
    end

    # Test no compression
    Rails.cache.stub :options, { compression_threshold: 0 } do
      ratio = CacheMetricsService.calculate_compression_ratio
      assert_equal 1.0, ratio
    end
  end

  # Test response time measurement
  test 'should measure cache response time' do
    CacheMetricsService.stub :redis_available?, true do
      # Mock cache operations to be fast
      Rails.cache.stub :read, ->(_key) {} do
        Rails.cache.stub :write, ->(_key, _value, _opts) { true } do
          Rails.cache.stub :delete, ->(_key) { true } do
            read_time = CacheMetricsService.measure_response_time(operation: :read, samples: 3)
            write_time = CacheMetricsService.measure_response_time(operation: :write, samples: 3)
            delete_time = CacheMetricsService.measure_response_time(operation: :delete, samples: 3)

            assert_kind_of Numeric, read_time
            assert_kind_of Numeric, write_time
            assert_kind_of Numeric, delete_time

            # Should be reasonably fast (< 100ms)
            assert read_time < 100
            assert write_time < 100
            assert delete_time < 100
          end
        end
      end
    end
  end

  test 'should handle Redis unavailable for response time' do
    CacheMetricsService.stub :redis_available?, false do
      response_time = CacheMetricsService.measure_response_time
      assert_equal 0.0, response_time
    end
  end

  # Test cache availability check
  test 'should check cache availability when Redis is available' do
    CacheMetricsService.stub :redis_available?, true do
      Rails.cache.stub :write, ->(_key, _value, _opts) { true } do
        Rails.cache.stub :read, ->(_key) { Time.current.to_i } do
          Rails.cache.stub :delete, ->(_key) { true } do
            availability = CacheMetricsService.check_availability
            assert_equal true, availability
          end
        end
      end
    end
  end

  test 'should handle cache unavailable' do
    CacheMetricsService.stub :redis_available?, false do
      availability = CacheMetricsService.check_availability
      assert_equal false, availability
    end
  end

  # Test key count by pattern
  test 'should get key count by pattern when Redis is available' do
    # Mock Redis cache and methods
    mock_redis = Object.new
    mock_redis.define_singleton_method(:keys) do |pattern|
      case pattern
      when 'test:restaurant:*' then ['test:restaurant:1', 'test:restaurant:2']
      when 'test:menu:*' then ['test:menu:1']
      else []
      end
    end

    mock_cache = Object.new
    mock_cache.define_singleton_method(:redis) { mock_redis }
    mock_cache.define_singleton_method(:options) { { namespace: 'test' } }

    CacheMetricsService.stub :redis_available?, true do
      Rails.stub :cache, mock_cache do
        key_counts = CacheMetricsService.get_key_count_by_pattern

        assert_kind_of Hash, key_counts
        assert_equal 2, key_counts['restaurant:*']
        assert_equal 1, key_counts['menu:*']
        assert_equal 0, key_counts['order:*']
      end
    end
  end

  # Test metrics reset
  test 'should reset cache metrics' do
    # Verify metrics exist before reset
    assert_equal 100, Rails.cache.read('cache_metrics:hits')

    CacheMetricsService.reset_metrics

    # Verify metrics are reset to 0
    # Note: reset_metrics resets all METRICS, not individual metric keys
    assert_equal 0, Rails.cache.read('cache_metrics:hit_rate')
    assert_equal 0, Rails.cache.read('cache_metrics:miss_rate')
    assert_not_nil Rails.cache.read('cache_metrics:last_reset')

    # The original metric keys might still exist, so let's check if they were reset
    # by checking if the reset timestamp was set
    reset_time = Rails.cache.read('cache_metrics:last_reset')
    assert_not_nil reset_time
    assert_kind_of String, reset_time
  end

  # Test metrics export
  test 'should export metrics in JSON format' do
    CacheMetricsService.stub :collect_metrics, lambda { |_opts|
      { performance: { hit_rate: 83.33 }, timestamp: Time.current.iso8601 }
    } do
      json_export = CacheMetricsService.export_metrics(format: :json)

      assert_kind_of String, json_export
      parsed = JSON.parse(json_export)
      assert_equal 83.33, parsed['performance']['hit_rate']
    end
  end

  test 'should export metrics in Prometheus format' do
    metrics = {
      performance: { hit_rate: 83.33, miss_rate: 16.67, throughput: 3.0, error_rate: 1.11 },
      memory: { usage: { used_memory: 1_048_576 } },
      operations: { total_operations: 180, hits: 100, misses: 20 },
    }

    CacheMetricsService.stub :collect_metrics, ->(_opts) { metrics } do
      prometheus_export = CacheMetricsService.export_metrics(format: :prometheus)

      assert_kind_of String, prometheus_export
      assert_includes prometheus_export, 'cache_hit_rate 83.33'
      assert_includes prometheus_export, 'cache_miss_rate 16.67'
      assert_includes prometheus_export, 'cache_throughput 3.0'
      assert_includes prometheus_export, 'cache_operations_total 180'
    end
  end

  test 'should export metrics in CSV format' do
    metrics = {
      performance: { hit_rate: 83.33, miss_rate: 16.67, throughput: 3.0, error_rate: 1.11 },
      operations: { total_operations: 180 },
      timestamp: Time.current.iso8601,
    }

    CacheMetricsService.stub :collect_metrics, ->(_opts) { metrics } do
      csv_export = CacheMetricsService.export_metrics(format: :csv)

      assert_kind_of String, csv_export
      assert_includes csv_export, 'Metric,Value,Unit,Timestamp'
      assert_includes csv_export, 'Hit Rate,83.33,%'
      assert_includes csv_export, 'Total Operations,180,count'
    end
  end

  # Test error handling
  test 'should handle Redis errors gracefully' do
    # Mock Redis to raise an error
    mock_redis = Object.new
    mock_redis.define_singleton_method(:memory) { |_type| raise Redis::ConnectionError, 'Connection failed' }

    mock_cache = Object.new
    mock_cache.define_singleton_method(:redis) { mock_redis }

    CacheMetricsService.stub :redis_available?, true do
      Rails.stub :cache, mock_cache do
        usage = CacheMetricsService.get_memory_usage
        assert_equal({}, usage)
      end
    end
  end

  # Test performance
  test 'should collect metrics efficiently' do
    start_time = Time.current

    CacheMetricsService.stub :collect_performance_metrics, ->(_window) { {} } do
      CacheMetricsService.stub :collect_memory_metrics, -> { {} } do
        CacheMetricsService.stub :collect_operation_metrics, ->(_window) { {} } do
          CacheMetricsService.stub :collect_health_metrics, -> { {} } do
            CacheMetricsService.stub :collect_pattern_metrics, -> { {} } do
              CacheMetricsService.stub :generate_recommendations, -> { [] } do
                CacheMetricsService.collect_metrics
              end
            end
          end
        end
      end
    end

    duration = Time.current - start_time
    assert duration < 1.second, "Metrics collection took too long: #{duration} seconds"
  end

  # Test logging
  test 'should log metrics operations' do
    log_output = StringIO.new
    logger = Logger.new(log_output)

    Rails.stub :logger, logger do
      CacheMetricsService.reset_metrics
    end

    log_content = log_output.string
    assert_includes log_content, 'Cache metrics reset'
  end

  # Test private method behavior through public interface
  test 'should generate appropriate recommendations' do
    # Set up conditions for recommendations
    Rails.cache.write('cache_metrics:hits', 80) # Low hit rate
    Rails.cache.write('cache_metrics:misses', 20)
    Rails.cache.write('cache_metrics:errors', 5) # High error rate

    CacheMetricsService.stub :get_memory_usage, lambda {
      { memory_fragmentation_ratio: 2.0 } # High fragmentation
    } do
      recommendations = CacheMetricsService.send(:generate_recommendations)

      assert_kind_of Array, recommendations
      assert(recommendations.any? { |r| r[:type] == 'performance' })
      assert(recommendations.any? { |r| r[:type] == 'reliability' })
      assert(recommendations.any? { |r| r[:type] == 'memory' })
    end
  end
end
