class MemoryMetric < ApplicationRecord
  validates :heap_size, presence: true, numericality: { greater_than: 0 }
  validates :timestamp, presence: true

  scope :recent, ->(timeframe) { where('timestamp > ?', timeframe.ago) }
  scope :ordered, -> { order(:timestamp) }

  # Calculate memory usage trend (bytes per hour)
  def self.memory_trend(timeframe = 1.hour)
    metrics = recent(timeframe).ordered
    return 0 if metrics.count < 2

    first_metric = metrics.first
    last_metric = metrics.last

    time_diff = (last_metric.timestamp - first_metric.timestamp) / 1.hour
    return 0 if time_diff.zero?

    memory_diff = last_metric.rss_memory - first_metric.rss_memory
    (memory_diff / time_diff).round(2)
  end

  # Detect potential memory leaks
  def self.detect_memory_leak(threshold_mb_per_hour = 50)
    trend = memory_trend(2.hours)
    threshold_bytes_per_hour = threshold_mb_per_hour * 1024 * 1024

    trend > threshold_bytes_per_hour
  end

  # Get current memory usage
  def self.current_memory_usage
    latest = order(:timestamp).last
    return 0 unless latest

    {
      heap_size: latest.heap_size,
      heap_free: latest.heap_free,
      rss_memory: latest.rss_memory,
      gc_count: latest.gc_count,
      timestamp: latest.timestamp,
    }
  end

  # Format memory size for display
  def formatted_rss_memory
    return '0 B' unless rss_memory

    units = %w[B KB MB GB TB]
    size = rss_memory.to_f
    unit_index = 0

    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end

    "#{size.round(2)} #{units[unit_index]}"
  end

  # Group memory metrics by time for trending
  def self.group_by_time(timeframe, interval = 5.minutes)
    recent(timeframe)
      .group_by { |metric| metric.timestamp.beginning_of_hour + ((metric.timestamp.min / interval.in_minutes).floor * interval) }
      .transform_values { |metrics| metrics.sum(&:rss_memory) / metrics.count.to_f }
  end
end
