require 'test_helper'

class MemoryMetricTest < ActiveSupport::TestCase
  def setup
    @memory_metric = MemoryMetric.create!(
      heap_size: 1024 * 1024,
      heap_free: 512,
      objects_allocated: 1000,
      gc_count: 5,
      rss_memory: 2048 * 1024,
      timestamp: Time.current,
    )
  end

  test 'should be valid with required attributes' do
    assert @memory_metric.valid?
  end

  test 'should require heap_size' do
    @memory_metric.heap_size = nil
    assert_not @memory_metric.valid?
    assert_includes @memory_metric.errors[:heap_size], "can't be blank"
  end

  test 'should require positive heap_size' do
    @memory_metric.heap_size = -1
    assert_not @memory_metric.valid?
    assert_includes @memory_metric.errors[:heap_size], 'must be greater than 0'
  end

  test 'should require timestamp' do
    @memory_metric.timestamp = nil
    assert_not @memory_metric.valid?
    assert_includes @memory_metric.errors[:timestamp], "can't be blank"
  end

  test 'recent scope should return metrics within timeframe' do
    old_metric = MemoryMetric.create!(
      heap_size: 1024,
      timestamp: 2.hours.ago,
    )

    recent_metrics = MemoryMetric.recent(1.hour)
    assert_includes recent_metrics, @memory_metric
    assert_not_includes recent_metrics, old_metric
  end

  test 'memory_trend should calculate trend' do
    # Create older metric
    MemoryMetric.create!(
      heap_size: 1024,
      rss_memory: 1024 * 1024,
      timestamp: 2.hours.ago,
    )

    # Create newer metric with higher memory
    MemoryMetric.create!(
      heap_size: 2048,
      rss_memory: 2048 * 1024,
      timestamp: 1.hour.ago,
    )

    trend = MemoryMetric.memory_trend(3.hours)
    assert trend.is_a?(Numeric)
  end

  test 'detect_memory_leak should detect leaks' do
    # Create metrics showing increasing memory usage
    base_time = 3.hours.ago
    base_memory = 100 * 1024 * 1024 # 100 MB

    (0..3).each do |hour|
      MemoryMetric.create!(
        heap_size: 1024,
        rss_memory: base_memory + (hour * 60 * 1024 * 1024), # Increase by 60MB per hour
        timestamp: base_time + hour.hours,
      )
    end

    leak_detected = MemoryMetric.detect_memory_leak(50) # 50 MB/hour threshold
    assert leak_detected
  end

  test 'current_memory_usage should return latest metrics' do
    # Create newer metric (more recent than setup metric)
    newer_metric = MemoryMetric.create!(
      heap_size: 2048,
      rss_memory: 4096,
      timestamp: 1.minute.from_now,
    )

    current = MemoryMetric.current_memory_usage
    assert_equal newer_metric.heap_size, current[:heap_size]
    assert_equal newer_metric.rss_memory, current[:rss_memory]
  end

  test 'formatted_rss_memory should format bytes correctly' do
    @memory_metric.rss_memory = 1024
    assert_equal '1.0 KB', @memory_metric.formatted_rss_memory

    @memory_metric.rss_memory = 1024 * 1024
    assert_equal '1.0 MB', @memory_metric.formatted_rss_memory

    @memory_metric.rss_memory = 1024 * 1024 * 1024
    assert_equal '1.0 GB', @memory_metric.formatted_rss_memory

    @memory_metric.rss_memory = nil
    assert_equal '0 B', @memory_metric.formatted_rss_memory
  end

  test 'group_by_time should group memory metrics by time intervals' do
    # Create metrics at different times
    MemoryMetric.create!(
      heap_size: 1024,
      rss_memory: 1024,
      timestamp: 10.minutes.ago,
    )

    MemoryMetric.create!(
      heap_size: 2048,
      rss_memory: 2048,
      timestamp: 5.minutes.ago,
    )

    grouped = MemoryMetric.group_by_time(1.hour, 5.minutes)
    assert grouped.is_a?(Hash)
    assert(grouped.values.all?(Numeric))
  end
end
