class MemoryMonitoringService
  MEMORY_LEAK_THRESHOLD = 50 # MB per hour

  def self.track_memory_usage
    return unless Rails.application.config.respond_to?(:enable_apm) && Rails.application.config.enable_apm

    gc_stats = GC.stat
    memory_stats = get_process_memory

    MemoryMetric.create!(
      heap_size: gc_stats[:heap_allocated_pages] * 16384, # 16KB per page
      heap_free: gc_stats[:heap_free_slots],
      objects_allocated: gc_stats[:total_allocated_objects],
      gc_count: gc_stats[:count],
      rss_memory: memory_stats[:rss],
      timestamp: Time.current,
    )
  rescue StandardError => e
    Rails.logger.error "Failed to track memory usage: #{e.message}"
  end

  def self.detect_memory_leaks
    return unless Rails.application.config.respond_to?(:enable_apm) && Rails.application.config.enable_apm

    trend = MemoryMetric.memory_trend(2.hours)
    threshold_bytes_per_hour = memory_leak_threshold_mb * 1024 * 1024

    if trend > threshold_bytes_per_hour
      PerformanceAlertJob.perform_later(
        type: 'memory_leak',
        trend: (trend / 1024 / 1024).round(2), # Convert to MB
        threshold: memory_leak_threshold_mb,
        severity: 'high',
      )
    end
  rescue StandardError => e
    Rails.logger.error "Failed to detect memory leaks: #{e.message}"
  end

  def self.memory_leak_threshold_mb
    Rails.application.config.memory_leak_threshold || MEMORY_LEAK_THRESHOLD
  end

  def self.get_process_memory
    if RUBY_PLATFORM.include?('linux')
      get_linux_memory
    elsif RUBY_PLATFORM.include?('darwin')
      get_macos_memory
    else
      get_fallback_memory
    end
  end

  def self.current_memory_snapshot
    gc_stats = GC.stat
    memory_stats = get_process_memory

    {
      heap_size: gc_stats[:heap_allocated_pages] * 16384,
      heap_free: gc_stats[:heap_free_slots],
      objects_allocated: gc_stats[:total_allocated_objects],
      gc_count: gc_stats[:count],
      rss_memory: memory_stats[:rss],
      formatted_rss: format_memory_size(memory_stats[:rss]),
      timestamp: Time.current,
    }
  end

  def self.format_memory_size(bytes)
    return '0 B' unless bytes&.positive?

    units = %w[B KB MB GB TB]
    size = bytes.to_f
    unit_index = 0

    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end

    "#{size.round(2)} #{units[unit_index]}"
  end

  def self.get_linux_memory
    # Linux: read from /proc/self/status
    status = File.read('/proc/self/status')
    rss_match = status.match(/VmRSS:\s*(\d+)\s*kB/)

    {
      rss: rss_match ? rss_match[1].to_i * 1024 : 0, # Convert KB to bytes
    }
  rescue StandardError
    { rss: 0 }
  end

  def self.get_macos_memory
    # macOS: use ps command
    pid = Process.pid
    rss_kb = `ps -o rss= -p #{pid}`.strip.to_i

    {
      rss: rss_kb * 1024, # Convert KB to bytes
    }
  rescue StandardError
    { rss: 0 }
  end

  def self.get_fallback_memory
    # Fallback: use Ruby's GC info as approximation
    gc_stats = GC.stat

    {
      rss: gc_stats[:heap_allocated_pages] * 16384, # Approximate
    }
  rescue StandardError
    { rss: 0 }
  end
end
