require 'test_helper'

class MetricsCollectorTest < ActiveSupport::TestCase
  def setup
    MetricsCollector.reset_metrics
  end

  def teardown
    MetricsCollector.reset_metrics
  end

  test 'increments counter metrics' do
    MetricsCollector.increment(:http_requests_total, 1, method: 'GET')
    MetricsCollector.increment(:http_requests_total, 2, method: 'GET')

    metrics = MetricsCollector.get_metrics
    key = 'http_requests_total{:method=>"GET"}'

    assert_equal 3, metrics[key][:value]
    assert_equal :counter, metrics[key][:type]
  end

  test 'sets gauge metrics' do
    MetricsCollector.set(:active_users, 42)

    metrics = MetricsCollector.get_metrics

    assert_equal 42, metrics['active_users'][:value]
    assert_equal :gauge, metrics['active_users'][:type]
  end

  test 'observes histogram metrics' do
    MetricsCollector.observe(:http_request_duration, 0.5)
    MetricsCollector.observe(:http_request_duration, 1.0)
    MetricsCollector.observe(:http_request_duration, 0.8)

    summary = MetricsCollector.get_metric_summary(:http_request_duration)

    assert_equal 3, summary[:count]
    assert_equal 2.3, summary[:sum]
    assert_in_delta 0.77, summary[:avg], 0.01
    assert_equal 0.5, summary[:min]
    assert_equal 1.0, summary[:max]
  end

  test 'times operations' do
    result = MetricsCollector.time(:http_request_duration) do
      sleep(0.01) # Small delay for timing
      'test_result'
    end

    assert_equal 'test_result', result

    summary = MetricsCollector.get_metric_summary(:http_request_duration)
    assert summary[:count].positive?
    assert summary[:avg].positive?
  end

  test 'handles labels correctly' do
    MetricsCollector.increment(:http_requests_total, 1, method: 'GET', status: '200')
    MetricsCollector.increment(:http_requests_total, 1, method: 'POST', status: '201')

    metrics = MetricsCollector.get_metrics

    # Should have separate entries for different label combinations
    get_key = metrics.keys.find { |k| k.include?('GET') }
    post_key = metrics.keys.find { |k| k.include?('POST') }

    assert_not_nil get_key
    assert_not_nil post_key
    assert_not_equal get_key, post_key
  end

  test 'validates metric types' do
    # Should work with valid metric types
    assert_nothing_raised do
      MetricsCollector.increment(:http_requests_total, 1)
    end

    # Should not crash with invalid metric names (just won't record)
    assert_nothing_raised do
      MetricsCollector.increment(:invalid_metric, 1)
    end
  end

  test 'collects system metrics' do
    MetricsCollector.collect_system_metrics

    metrics = MetricsCollector.get_metrics

    # Should have some system metrics
    assert(metrics.keys.any? { |k| k.include?('memory_usage') || k.include?('db_pool') })
  end

  test 'metric summary handles empty metrics' do
    summary = MetricsCollector.get_metric_summary(:nonexistent_metric)
    assert_nil summary
  end

  test 'histogram keeps limited number of values' do
    # Add more than 1000 values
    1100.times do |i|
      MetricsCollector.observe(:http_request_duration, i)
    end

    metrics = MetricsCollector.get_metrics
    histogram_data = metrics['http_request_duration']

    # Should keep only last 1000 values
    assert_equal 1000, histogram_data[:values].size
  end
end
