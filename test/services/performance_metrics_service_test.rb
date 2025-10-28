require 'test_helper'

class PerformanceMetricsServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)

    # Create test performance metrics
    @recent_metric = PerformanceMetric.create!(
      endpoint: 'GET /restaurants',
      response_time: 250.5,
      status_code: 200,
      user: @user,
      controller: 'restaurants',
      action: 'index',
      timestamp: 5.minutes.ago,
      memory_usage: 1024,
    )

    @error_metric = PerformanceMetric.create!(
      endpoint: 'GET /error',
      response_time: 100,
      status_code: 500,
      timestamp: 3.minutes.ago,
    )

    # Create test memory metrics
    @memory_metric = MemoryMetric.create!(
      heap_size: 1024 * 1024,
      rss_memory: 2048 * 1024,
      timestamp: 2.minutes.ago,
    )

    # Create test slow query
    @slow_query = SlowQuery.create!(
      sql: 'SELECT * FROM restaurants WHERE user_id = $1',
      duration: 150.5,
      timestamp: 1.minute.ago,
    )
  end

  test 'current_snapshot should return current metrics' do
    snapshot = PerformanceMetricsService.current_snapshot

    assert snapshot.key?(:avg_response_time)
    assert snapshot.key?(:current_memory_usage)
    assert snapshot.key?(:cache_hit_rate)
    assert snapshot.key?(:active_users)
    assert snapshot.key?(:error_rate)
    assert snapshot.key?(:slow_queries_count)
    assert snapshot.key?(:timestamp)

    assert snapshot[:avg_response_time].positive?
    assert snapshot[:active_users] >= 0
    assert snapshot[:error_rate] >= 0
    assert snapshot[:slow_queries_count] >= 0
  end

  test 'trends should return trend data' do
    trends = PerformanceMetricsService.trends(1.hour)

    assert trends.key?(:response_time_trend)
    assert trends.key?(:memory_trend)
    assert trends.key?(:error_trend)
    assert trends.key?(:slow_queries_trend)

    assert trends[:response_time_trend].is_a?(Hash)
    assert trends[:memory_trend].is_a?(Hash)
    assert trends[:error_trend].is_a?(Hash)
    assert trends[:slow_queries_trend].is_a?(Hash)
  end

  test 'slow_endpoints should return slowest endpoints' do
    # Create additional metrics for different endpoints
    PerformanceMetric.create!(
      endpoint: 'GET /slow',
      response_time: 500,
      status_code: 200,
      timestamp: Time.current,
    )

    PerformanceMetric.create!(
      endpoint: 'GET /fast',
      response_time: 50,
      status_code: 200,
      timestamp: Time.current,
    )

    slow_endpoints = PerformanceMetricsService.slow_endpoints(1.hour, 5)

    assert slow_endpoints.is_a?(Array)
    assert(slow_endpoints.all? { |e| e.key?(:endpoint) && e.key?(:avg_response_time) })

    # Should be ordered by response time (slowest first)
    if slow_endpoints.length > 1
      assert slow_endpoints.first[:avg_response_time] >= slow_endpoints.last[:avg_response_time]
    end
  end

  test 'endpoint_analysis should analyze specific endpoint' do
    # Create more metrics for the same endpoint
    3.times do |i|
      PerformanceMetric.create!(
        endpoint: 'GET /restaurants',
        response_time: 200 + (i * 50),
        status_code: 200,
        timestamp: (i + 1).minutes.ago,
      )
    end

    analysis = PerformanceMetricsService.endpoint_analysis('GET /restaurants', 1.hour)

    assert analysis.present?
    assert_equal 'GET /restaurants', analysis[:endpoint]
    assert analysis[:total_requests].positive?
    assert analysis[:avg_response_time].positive?
    assert analysis.key?(:min_response_time)
    assert analysis.key?(:max_response_time)
    assert analysis.key?(:p50_response_time)
    assert analysis.key?(:p95_response_time)
    assert analysis.key?(:p99_response_time)
    assert analysis.key?(:error_rate)
    assert analysis.key?(:requests_per_hour)
    assert analysis.key?(:trend)
  end

  test 'endpoint_analysis should return nil for non-existent endpoint' do
    analysis = PerformanceMetricsService.endpoint_analysis('GET /nonexistent', 1.hour)
    assert_nil analysis
  end

  test 'performance_summary should return comprehensive summary' do
    summary = PerformanceMetricsService.performance_summary(1.hour)

    assert summary.key?(:overview)
    assert summary.key?(:trends)
    assert summary.key?(:slow_endpoints)
    assert summary.key?(:slow_queries)
    assert summary.key?(:memory_analysis)

    # Check overview structure
    overview = summary[:overview]
    assert overview.key?(:avg_response_time)
    assert overview.key?(:current_memory_usage)
    assert overview.key?(:error_rate)

    # Check memory analysis structure
    memory_analysis = summary[:memory_analysis]
    assert memory_analysis.key?(:current)
    assert memory_analysis.key?(:trend)
    assert memory_analysis.key?(:leak_detected)

    # Check slow queries structure
    slow_queries = summary[:slow_queries]
    assert slow_queries.is_a?(Array)
    if slow_queries.any?
      query = slow_queries.first
      assert query.key?(:sql)
      assert query.key?(:duration)
      assert query.key?(:table)
      assert query.key?(:timestamp)
    end
  end

  test 'private methods should calculate metrics correctly' do
    # Test avg_response_time calculation
    avg_time = PerformanceMetricsService.send(:calculate_avg_response_time, 1.hour)
    assert avg_time >= 0

    # Test error rate calculation
    error_rate = PerformanceMetricsService.send(:calculate_error_rate, 1.hour)
    assert error_rate >= 0
    assert error_rate <= 100

    # Test active users count
    active_users = PerformanceMetricsService.send(:count_active_users, 1.hour)
    assert active_users >= 0

    # Test slow queries count
    slow_queries_count = PerformanceMetricsService.send(:count_slow_queries, 1.hour)
    assert slow_queries_count >= 0
  end

  test 'time bucketing should work correctly' do
    timestamp = Time.zone.parse('2023-10-12 14:23:45')

    # 5-minute intervals
    bucket = PerformanceMetricsService.send(:time_bucket, timestamp, 5.minutes)
    expected = Time.zone.parse('2023-10-12 14:20:00')
    assert_equal expected, bucket

    # 15-minute intervals
    bucket = PerformanceMetricsService.send(:time_bucket, timestamp, 15.minutes)
    expected = Time.zone.parse('2023-10-12 14:15:00')
    assert_equal expected, bucket

    # 1-hour intervals
    bucket = PerformanceMetricsService.send(:time_bucket, timestamp, 1.hour)
    expected = Time.zone.parse('2023-10-12 14:00:00')
    assert_equal expected, bucket
  end

  test 'percentile calculation should work correctly' do
    values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    p50 = PerformanceMetricsService.send(:percentile, values, 50)
    assert_equal 6, p50

    p95 = PerformanceMetricsService.send(:percentile, values, 95)
    assert_equal 10, p95

    # Empty array
    p50_empty = PerformanceMetricsService.send(:percentile, [], 50)
    assert_equal 0, p50_empty
  end

  test 'interval calculation should adjust based on timeframe' do
    interval_5m = PerformanceMetricsService.send(:calculate_interval, 30.minutes)
    assert_equal 5.minutes, interval_5m

    interval_15m = PerformanceMetricsService.send(:calculate_interval, 3.hours)
    assert_equal 15.minutes, interval_15m

    interval_1h = PerformanceMetricsService.send(:calculate_interval, 12.hours)
    assert_equal 1.hour, interval_1h

    interval_4h = PerformanceMetricsService.send(:calculate_interval, 7.days)
    assert_equal 4.hours, interval_4h
  end
end
