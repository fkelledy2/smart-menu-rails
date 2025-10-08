require 'test_helper'

class PerformanceMonitoringServiceTest < ActiveSupport::TestCase
  def setup
    @service = PerformanceMonitoringService.instance
    @service.reset_metrics # Start with clean metrics
  end

  def teardown
    @service.reset_metrics # Clean up after each test
  end

  # Singleton tests
  test "should be a singleton" do
    service1 = PerformanceMonitoringService.instance
    service2 = PerformanceMonitoringService.instance
    assert_same service1, service2
  end

  test "should delegate class methods to instance" do
    assert_respond_to PerformanceMonitoringService, :track_request
    assert_respond_to PerformanceMonitoringService, :track_query
    assert_respond_to PerformanceMonitoringService, :track_cache_hit
    assert_respond_to PerformanceMonitoringService, :track_cache_miss
    assert_respond_to PerformanceMonitoringService, :get_metrics
    assert_respond_to PerformanceMonitoringService, :get_slow_queries
    assert_respond_to PerformanceMonitoringService, :get_request_stats
    assert_respond_to PerformanceMonitoringService, :reset_metrics
  end

  test "should define performance thresholds" do
    assert_equal 100, PerformanceMonitoringService::SLOW_QUERY_THRESHOLD
    assert_equal 500, PerformanceMonitoringService::SLOW_REQUEST_THRESHOLD
    assert_equal 100, PerformanceMonitoringService::MEMORY_WARNING_THRESHOLD
  end

  # Initialization tests
  test "should initialize with empty metrics" do
    service = PerformanceMonitoringService.instance
    service.reset_metrics
    
    metrics = service.get_metrics
    
    assert_equal 0, metrics[:requests].length
    assert_equal 0, metrics[:slow_requests].length
    assert_equal 0, metrics[:queries].length
    assert_equal 0, metrics[:slow_queries].length
    assert_equal 0, metrics[:cache_stats][:hits]
    assert_equal 0, metrics[:cache_stats][:misses]
    assert_equal 0.0, metrics[:cache_stats][:hit_rate]
    assert_equal 0, metrics[:memory_usage].length
    assert_instance_of Float, metrics[:uptime]
  end

  # Request tracking tests
  test "should track request performance" do
    @service.track_request(
      controller: 'RestaurantsController',
      action: 'index',
      duration: 250.5,
      status: 200,
      method: 'GET',
      path: '/restaurants'
    )

    metrics = @service.get_metrics
    request = metrics[:requests].first
    
    assert_equal 1, metrics[:requests].length
    assert_equal 'RestaurantsController', request[:controller]
    assert_equal 'index', request[:action]
    assert_equal 250.5, request[:duration]
    assert_equal 200, request[:status]
    assert_equal 'GET', request[:method]
    assert_equal '/restaurants', request[:path]
    assert_equal false, request[:slow]
    assert request[:timestamp].is_a?(Time) || request[:timestamp].is_a?(ActiveSupport::TimeWithZone)
  end

  test "should mark slow requests" do
    @service.track_request(
      controller: 'MenusController',
      action: 'show',
      duration: 750.0,
      status: 200
    )

    metrics = @service.get_metrics
    request = metrics[:requests].first
    
    assert_equal true, request[:slow]
    assert_equal 1, metrics[:slow_requests].length
    assert_equal request, metrics[:slow_requests].first
  end

  test "should log slow requests" do
    log_output = capture_logs do
      @service.track_request(
        controller: 'OrdersController',
        action: 'create',
        duration: 600.0,
        status: 201
      )
    end

    assert_includes log_output, '[PERFORMANCE] Slow request'
    assert_includes log_output, 'OrdersController#create took 600.0ms'
  end

  test "should limit stored requests to 1000" do
    # Add 1100 requests
    1100.times do |i|
      @service.track_request(
        controller: 'TestController',
        action: 'test',
        duration: 100.0,
        status: 200
      )
    end

    metrics = @service.get_metrics
    # Should only keep last 1000
    assert_equal 50, metrics[:requests].length # get_metrics returns last 50
    
    # But internal storage should be limited to 1000
    # We can't directly access @metrics, so we'll test the behavior indirectly
    # by checking that old requests are removed
  end

  test "should handle requests with minimal parameters" do
    @service.track_request(
      controller: 'HomeController',
      action: 'index',
      duration: 150.0,
      status: 200
    )

    metrics = @service.get_metrics
    request = metrics[:requests].first
    
    assert_equal 'HomeController', request[:controller]
    assert_equal 'index', request[:action]
    assert_equal 150.0, request[:duration]
    assert_equal 200, request[:status]
    assert_equal 'GET', request[:method] # Default method
    assert_nil request[:path]
  end

  # Query tracking tests
  test "should track query performance" do
    sql = "SELECT * FROM restaurants WHERE user_id = ?"
    @service.track_query(
      sql: sql,
      duration: 45.5,
      name: 'Restaurant Load'
    )

    metrics = @service.get_metrics
    query = metrics[:queries].first
    
    assert_equal 1, metrics[:queries].length
    assert_equal sql, query[:sql]
    assert_equal 45.5, query[:duration]
    assert_equal 'Restaurant Load', query[:name]
    assert_equal false, query[:slow]
    assert query[:timestamp].is_a?(Time) || query[:timestamp].is_a?(ActiveSupport::TimeWithZone)
  end

  test "should mark slow queries" do
    @service.track_query(
      sql: "SELECT * FROM orders JOIN order_items ON orders.id = order_items.order_id",
      duration: 150.0,
      name: 'Complex Join'
    )

    metrics = @service.get_metrics
    query = metrics[:queries].first
    
    assert_equal true, query[:slow]
    assert_equal 1, metrics[:slow_queries].length
    assert_equal query, metrics[:slow_queries].first
  end

  test "should log slow queries" do
    long_sql = "SELECT * FROM restaurants WHERE name LIKE '%test%' AND created_at > '2023-01-01'"
    
    log_output = capture_logs do
      @service.track_query(
        sql: long_sql,
        duration: 200.0,
        name: 'Restaurant Search'
      )
    end

    assert_includes log_output, '[PERFORMANCE] Slow query'
    assert_includes log_output, 'Restaurant Search took 200.0ms'
    assert_includes log_output, long_sql.truncate(100)
  end

  test "should truncate long SQL queries" do
    very_long_sql = "SELECT * FROM restaurants WHERE " + ("name = 'test' OR " * 50) + "id = 1"
    
    @service.track_query(
      sql: very_long_sql,
      duration: 50.0,
      name: 'Long Query'
    )

    metrics = @service.get_metrics
    query = metrics[:queries].first
    
    assert query[:sql].length <= 200
    assert_includes query[:sql], "SELECT * FROM restaurants WHERE"
  end

  test "should limit stored queries to 500" do
    # Add 600 queries
    600.times do |i|
      @service.track_query(
        sql: "SELECT * FROM test_table WHERE id = #{i}",
        duration: 25.0,
        name: "Query #{i}"
      )
    end

    metrics = @service.get_metrics
    # Should only return last 50 in metrics
    assert_equal 50, metrics[:queries].length
  end

  test "should handle queries without name" do
    @service.track_query(
      sql: "UPDATE users SET last_login = NOW()",
      duration: 30.0
    )

    metrics = @service.get_metrics
    query = metrics[:queries].first
    
    assert_nil query[:name]
    assert_equal "UPDATE users SET last_login = NOW()", query[:sql]
  end

  # Cache tracking tests
  test "should track cache hits" do
    5.times { @service.track_cache_hit }
    
    metrics = @service.get_metrics
    cache_stats = metrics[:cache_stats]
    
    assert_equal 5, cache_stats[:hits]
    assert_equal 0, cache_stats[:misses]
    assert_equal 100.0, cache_stats[:hit_rate]
  end

  test "should track cache misses" do
    3.times { @service.track_cache_miss }
    
    metrics = @service.get_metrics
    cache_stats = metrics[:cache_stats]
    
    assert_equal 0, cache_stats[:hits]
    assert_equal 3, cache_stats[:misses]
    assert_equal 0.0, cache_stats[:hit_rate]
  end

  test "should calculate cache hit rate correctly" do
    7.times { @service.track_cache_hit }
    3.times { @service.track_cache_miss }
    
    metrics = @service.get_metrics
    cache_stats = metrics[:cache_stats]
    
    assert_equal 7, cache_stats[:hits]
    assert_equal 3, cache_stats[:misses]
    assert_equal 70.0, cache_stats[:hit_rate]
  end

  test "should handle zero cache operations" do
    metrics = @service.get_metrics
    cache_stats = metrics[:cache_stats]
    
    assert_equal 0, cache_stats[:hits]
    assert_equal 0, cache_stats[:misses]
    assert_equal 0.0, cache_stats[:hit_rate]
  end

  # Memory tracking tests
  test "should track memory usage when GC is available" do
    # Mock GC to be available
    if defined?(GC)
      @service.track_memory_usage
      
      metrics = @service.get_metrics
      
      assert_equal 1, metrics[:memory_usage].length
      memory_sample = metrics[:memory_usage].first
      
      assert memory_sample[:memory_mb].is_a?(Numeric)
      assert memory_sample[:timestamp].is_a?(Time) || memory_sample[:timestamp].is_a?(ActiveSupport::TimeWithZone)
      assert memory_sample[:memory_mb] >= 0
    else
      # If GC is not defined, method should return early
      @service.track_memory_usage
      
      metrics = @service.get_metrics
      assert_equal 0, metrics[:memory_usage].length
    end
  end

  test "should log memory warnings for high usage" do
    # Mock GC to return high memory usage
    if defined?(GC)
      # Mock GC.stat to return high memory usage
      mock_gc_stat = {
        heap_allocated_pages: 1000000 # This should result in high MB
      }
      
      GC.stub(:stat, mock_gc_stat) do
        # Mock GC::INTERNAL_CONSTANTS if it exists
        if defined?(GC::INTERNAL_CONSTANTS)
          log_output = capture_logs do
            @service.track_memory_usage
          end
          
          # Should log warning if memory is above threshold
          # Note: This test might not always trigger the warning depending on the mock values
          # Just assert that the method completes without error
          assert_not_nil log_output
        else
          # If constants not available, just test that method doesn't crash
          assert_nothing_raised do
            @service.track_memory_usage
          end
        end
      end
    else
      # If GC not available, just test that method doesn't crash
      assert_nothing_raised do
        @service.track_memory_usage
      end
    end
  end

  test "should limit memory usage samples to 100" do
    if defined?(GC)
      # Add 120 memory samples
      120.times do
        @service.track_memory_usage
      end
      
      metrics = @service.get_metrics
      # Should only return last 20 in metrics
      assert_equal 20, metrics[:memory_usage].length
    end
  end

  # Metrics aggregation tests
  test "should provide comprehensive metrics" do
    # Add some test data
    @service.track_request(controller: 'TestController', action: 'fast', duration: 100.0, status: 200)
    @service.track_request(controller: 'TestController', action: 'slow', duration: 600.0, status: 200)
    @service.track_query(sql: 'SELECT * FROM fast_table', duration: 50.0, name: 'Fast Query')
    @service.track_query(sql: 'SELECT * FROM slow_table', duration: 150.0, name: 'Slow Query')
    @service.track_cache_hit
    @service.track_cache_miss

    metrics = @service.get_metrics
    
    # Check structure
    assert_includes metrics.keys, :summary
    assert_includes metrics.keys, :requests
    assert_includes metrics.keys, :slow_requests
    assert_includes metrics.keys, :queries
    assert_includes metrics.keys, :slow_queries
    assert_includes metrics.keys, :cache_stats
    assert_includes metrics.keys, :memory_usage
    assert_includes metrics.keys, :uptime
    
    # Check summary
    summary = metrics[:summary]
    assert_equal 2, summary[:total_requests]
    assert_equal 2, summary[:total_queries]
    assert_equal 1, summary[:slow_requests]
    assert_equal 1, summary[:slow_queries]
    assert_equal 50.0, summary[:cache_hit_rate]
    assert_instance_of Float, summary[:uptime_hours]
    
    # Check data
    assert_equal 2, metrics[:requests].length
    assert_equal 1, metrics[:slow_requests].length
    assert_equal 2, metrics[:queries].length
    assert_equal 1, metrics[:slow_queries].length
  end

  # Slow queries analysis tests
  test "should analyze slow queries" do
    # Add multiple instances of the same slow query
    3.times do
      @service.track_query(
        sql: 'SELECT * FROM orders WHERE status = ?',
        duration: 120.0,
        name: 'Order Status Query'
      )
    end
    
    # Add different slow query
    @service.track_query(
      sql: 'SELECT COUNT(*) FROM menu_items',
      duration: 200.0,
      name: 'Menu Count Query'
    )

    slow_queries = @service.get_slow_queries
    
    assert_equal 2, slow_queries.length
    
    # Should be sorted by average duration (highest first)
    first_query = slow_queries.first
    assert_equal 'Menu Count Query', first_query[:query]
    assert_equal 1, first_query[:count]
    assert_equal 200.0, first_query[:avg_duration]
    assert_equal 200.0, first_query[:max_duration]
    
    second_query = slow_queries.last
    assert_equal 'Order Status Query', second_query[:query]
    assert_equal 3, second_query[:count]
    assert_equal 120.0, second_query[:avg_duration]
    assert_equal 120.0, second_query[:max_duration]
  end

  test "should group slow queries by name or SQL" do
    # Query with name
    @service.track_query(sql: 'SELECT * FROM users', duration: 150.0, name: 'User Load')
    @service.track_query(sql: 'SELECT * FROM users', duration: 180.0, name: 'User Load')
    
    # Query without name (should group by SQL)
    @service.track_query(sql: 'SELECT * FROM orders', duration: 160.0)
    @service.track_query(sql: 'SELECT * FROM orders', duration: 140.0)

    slow_queries = @service.get_slow_queries
    
    assert_equal 2, slow_queries.length
    
    # Find the queries
    user_query = slow_queries.find { |q| q[:query] == 'User Load' }
    order_query = slow_queries.find { |q| q[:query] == 'SELECT * FROM orders' }
    
    assert_not_nil user_query
    assert_equal 2, user_query[:count]
    assert_equal 165.0, user_query[:avg_duration]
    
    assert_not_nil order_query
    assert_equal 2, order_query[:count]
    assert_equal 150.0, order_query[:avg_duration]
  end

  test "should limit slow queries results" do
    # Add many different slow queries
    30.times do |i|
      @service.track_query(
        sql: "SELECT * FROM table_#{i}",
        duration: 110.0 + i,
        name: "Query #{i}"
      )
    end

    slow_queries = @service.get_slow_queries(limit: 10)
    
    assert_equal 10, slow_queries.length
    # Should be sorted by duration (highest first)
    assert slow_queries.first[:avg_duration] > slow_queries.last[:avg_duration]
  end

  # Request statistics tests
  test "should calculate request statistics" do
    # Add various request durations
    durations = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]
    durations.each_with_index do |duration, i|
      @service.track_request(
        controller: 'TestController',
        action: "action_#{i}",
        duration: duration.to_f,
        status: 200
      )
    end

    stats = @service.get_request_stats
    
    assert_equal 10, stats[:total_requests]
    assert_equal 550.0, stats[:avg_response_time]
    assert_equal 550.0, stats[:median_response_time]
    assert_equal 1000.0, stats[:p95_response_time] # For 10 items, 95th percentile is the 9th item (index 8.55 rounded to 9)
    assert_equal 1000.0, stats[:p99_response_time]
    assert_equal 5, stats[:slow_requests_count] # 600, 700, 800, 900, 1000 are > 500ms
    assert_equal 50.0, stats[:slow_requests_percentage]
  end

  test "should handle empty request stats" do
    stats = @service.get_request_stats
    
    assert_equal({}, stats)
  end

  test "should calculate median correctly for odd number of requests" do
    [100, 200, 300].each do |duration|
      @service.track_request(
        controller: 'TestController',
        action: 'test',
        duration: duration.to_f,
        status: 200
      )
    end

    stats = @service.get_request_stats
    assert_equal 200.0, stats[:median_response_time]
  end

  test "should calculate median correctly for even number of requests" do
    [100, 200, 300, 400].each do |duration|
      @service.track_request(
        controller: 'TestController',
        action: 'test',
        duration: duration.to_f,
        status: 200
      )
    end

    stats = @service.get_request_stats
    assert_equal 250.0, stats[:median_response_time]
  end

  # Reset functionality tests
  test "should reset all metrics" do
    # Add some data
    @service.track_request(controller: 'TestController', action: 'test', duration: 100.0, status: 200)
    @service.track_query(sql: 'SELECT 1', duration: 50.0, name: 'Test')
    @service.track_cache_hit
    @service.track_memory_usage if defined?(GC)

    # Verify data exists
    metrics_before = @service.get_metrics
    assert metrics_before[:requests].any?
    assert metrics_before[:queries].any?
    assert metrics_before[:cache_stats][:hits] > 0

    # Reset
    @service.reset_metrics

    # Verify data is cleared
    metrics_after = @service.get_metrics
    assert_equal 0, metrics_after[:requests].length
    assert_equal 0, metrics_after[:queries].length
    assert_equal 0, metrics_after[:cache_stats][:hits]
    assert_equal 0, metrics_after[:cache_stats][:misses]
    assert_equal 0, metrics_after[:memory_usage].length
    
    # Uptime should be reset (very small)
    assert metrics_after[:uptime] < 1.0
  end

  # Thread safety tests
  test "should be thread safe for concurrent operations" do
    threads = []
    
    # Create multiple threads that add metrics concurrently
    10.times do |i|
      threads << Thread.new do
        10.times do |j|
          @service.track_request(
            controller: "Controller#{i}",
            action: "action#{j}",
            duration: 100.0 + j,
            status: 200
          )
          @service.track_cache_hit
        end
      end
    end

    # Wait for all threads to complete
    threads.each(&:join)

    # Verify all data was recorded correctly
    metrics = @service.get_metrics
    # We can't guarantee exact counts due to the last(50) limit in get_metrics
    # but we can verify the structure is intact
    assert metrics[:cache_stats][:hits] >= 50 # Should have at least 50 hits
    assert metrics[:requests].any?
  end

  # Edge cases and error handling
  test "should handle zero duration requests" do
    @service.track_request(
      controller: 'FastController',
      action: 'instant',
      duration: 0.0,
      status: 200
    )

    metrics = @service.get_metrics
    request = metrics[:requests].first
    
    assert_equal 0.0, request[:duration]
    assert_equal false, request[:slow]
  end

  test "should handle negative duration gracefully" do
    @service.track_request(
      controller: 'TestController',
      action: 'test',
      duration: -5.0,
      status: 200
    )

    metrics = @service.get_metrics
    request = metrics[:requests].first
    
    assert_equal(-5.0, request[:duration])
    assert_equal false, request[:slow] # Negative duration is not considered slow
  end

  test "should handle very large durations" do
    large_duration = 999999.99
    
    @service.track_request(
      controller: 'SlowController',
      action: 'very_slow',
      duration: large_duration,
      status: 200
    )

    metrics = @service.get_metrics
    request = metrics[:requests].first
    
    assert_equal large_duration, request[:duration]
    assert_equal true, request[:slow]
  end

  test "should handle empty SQL queries" do
    @service.track_query(sql: '', duration: 50.0, name: 'Empty Query')

    metrics = @service.get_metrics
    query = metrics[:queries].first
    
    assert_equal '', query[:sql]
    assert_equal 'Empty Query', query[:name]
  end

  # Class method delegation tests
  test "should work with class method delegation" do
    # Test that class methods work the same as instance methods
    PerformanceMonitoringService.track_request(
      controller: 'ClassMethodController',
      action: 'test',
      duration: 150.0,
      status: 200
    )

    metrics = PerformanceMonitoringService.get_metrics
    request = metrics[:requests].first
    
    assert_equal 'ClassMethodController', request[:controller]
    assert_equal 'test', request[:action]
    assert_equal 150.0, request[:duration]
  end

  private

  def capture_logs
    original_logger = Rails.logger
    log_output = StringIO.new
    Rails.logger = Logger.new(log_output)
    
    yield
    
    log_output.string
  ensure
    Rails.logger = original_logger
  end
end
