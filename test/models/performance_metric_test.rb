require 'test_helper'

class PerformanceMetricTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @performance_metric = PerformanceMetric.create!(
      endpoint: 'GET /restaurants',
      response_time: 250.5,
      status_code: 200,
      user: @user,
      controller: 'restaurants',
      action: 'index',
      timestamp: Time.current,
      memory_usage: 1024,
    )
  end

  test 'should be valid with required attributes' do
    assert @performance_metric.valid?
  end

  test 'should require endpoint' do
    @performance_metric.endpoint = nil
    assert_not @performance_metric.valid?
    assert_includes @performance_metric.errors[:endpoint], "can't be blank"
  end

  test 'should require response_time' do
    @performance_metric.response_time = nil
    assert_not @performance_metric.valid?
    assert_includes @performance_metric.errors[:response_time], "can't be blank"
  end

  test 'should require positive response_time' do
    @performance_metric.response_time = -1
    assert_not @performance_metric.valid?
    assert_includes @performance_metric.errors[:response_time], 'must be greater than 0'
  end

  test 'should require valid status_code' do
    @performance_metric.status_code = 99
    assert_not @performance_metric.valid?

    @performance_metric.status_code = 600
    assert_not @performance_metric.valid?

    @performance_metric.status_code = 200
    assert @performance_metric.valid?
  end

  test 'should allow optional user' do
    @performance_metric.user = nil
    assert @performance_metric.valid?
  end

  test 'recent scope should return metrics within timeframe' do
    old_metric = PerformanceMetric.create!(
      endpoint: 'GET /menus',
      response_time: 100,
      status_code: 200,
      timestamp: 2.hours.ago,
    )

    recent_metrics = PerformanceMetric.recent(1.hour)
    assert_includes recent_metrics, @performance_metric
    assert_not_includes recent_metrics, old_metric
  end

  test 'slow scope should return slow metrics' do
    fast_metric = PerformanceMetric.create!(
      endpoint: 'GET /fast',
      response_time: 50,
      status_code: 200,
      timestamp: Time.current,
    )

    slow_metrics = PerformanceMetric.slow(100)
    assert_includes slow_metrics, @performance_metric
    assert_not_includes slow_metrics, fast_metric
  end

  test 'errors scope should return error responses' do
    error_metric = PerformanceMetric.create!(
      endpoint: 'GET /error',
      response_time: 100,
      status_code: 500,
      timestamp: Time.current,
    )

    error_metrics = PerformanceMetric.errors
    assert_includes error_metrics, error_metric
    assert_not_includes error_metrics, @performance_metric
  end

  test 'avg_response_time should calculate average' do
    PerformanceMetric.create!(
      endpoint: 'GET /test',
      response_time: 100,
      status_code: 200,
      timestamp: Time.current,
    )

    PerformanceMetric.create!(
      endpoint: 'GET /test',
      response_time: 200,
      status_code: 200,
      timestamp: Time.current,
    )

    avg = PerformanceMetric.avg_response_time(1.hour)
    assert avg.positive?
  end

  test 'error_rate should calculate percentage' do
    # Create error metric
    PerformanceMetric.create!(
      endpoint: 'GET /error',
      response_time: 100,
      status_code: 500,
      timestamp: Time.current,
    )

    error_rate = PerformanceMetric.error_rate(1.hour)
    assert error_rate.positive?
    assert error_rate <= 100
  end

  test 'slowest_endpoints should return ordered results' do
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

    slowest = PerformanceMetric.slowest_endpoints(5, 1.hour)
    assert slowest.first[0] == 'GET /slow'
  end

  test 'group_by_time should group metrics by time intervals' do
    # Create metrics at different times
    PerformanceMetric.create!(
      endpoint: 'GET /test1',
      response_time: 100,
      status_code: 200,
      timestamp: 10.minutes.ago,
    )

    PerformanceMetric.create!(
      endpoint: 'GET /test2',
      response_time: 200,
      status_code: 200,
      timestamp: 5.minutes.ago,
    )

    grouped = PerformanceMetric.group_by_time(1.hour, 5.minutes)
    assert grouped.is_a?(Hash)
    assert(grouped.values.all?(Numeric))
  end
end
