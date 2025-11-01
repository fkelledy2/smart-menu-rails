require 'test_helper'

class MemoryMonitoringServiceTest < ActiveSupport::TestCase
  test 'returns memory leak threshold' do
    threshold = MemoryMonitoringService.memory_leak_threshold_mb
    assert_kind_of Integer, threshold
    assert threshold > 0
  end

  test 'default memory leak threshold is 50 MB' do
    assert_equal 50, MemoryMonitoringService::MEMORY_LEAK_THRESHOLD
  end

  test 'gets process memory' do
    memory = MemoryMonitoringService.get_process_memory
    
    assert_kind_of Hash, memory
    assert_includes memory.keys, :rss
    assert_kind_of Integer, memory[:rss]
  end

  test 'current memory snapshot includes expected keys' do
    snapshot = MemoryMonitoringService.current_memory_snapshot
    
    assert_includes snapshot.keys, :heap_size
    assert_includes snapshot.keys, :heap_free
    assert_includes snapshot.keys, :objects_allocated
    assert_includes snapshot.keys, :gc_count
    assert_includes snapshot.keys, :rss_memory
    assert_includes snapshot.keys, :formatted_rss
    assert_includes snapshot.keys, :timestamp
  end

  test 'formats memory size in bytes' do
    formatted = MemoryMonitoringService.format_memory_size(1024)
    assert_equal '1.0 KB', formatted
  end

  test 'formats memory size in kilobytes' do
    formatted = MemoryMonitoringService.format_memory_size(1024 * 1024)
    assert_equal '1.0 MB', formatted
  end

  test 'formats memory size in megabytes' do
    formatted = MemoryMonitoringService.format_memory_size(1024 * 1024 * 1024)
    assert_equal '1.0 GB', formatted
  end

  test 'formats zero bytes' do
    formatted = MemoryMonitoringService.format_memory_size(0)
    assert_equal '0 B', formatted
  end

  test 'formats nil bytes' do
    formatted = MemoryMonitoringService.format_memory_size(nil)
    assert_equal '0 B', formatted
  end

  test 'formats small byte values' do
    formatted = MemoryMonitoringService.format_memory_size(512)
    assert_equal '512.0 B', formatted
  end

  test 'get_fallback_memory returns hash with rss' do
    memory = MemoryMonitoringService.get_fallback_memory
    
    assert_kind_of Hash, memory
    assert_includes memory.keys, :rss
    assert memory[:rss] >= 0
  end

  test 'track_memory_usage does not raise errors' do
    assert_nothing_raised do
      MemoryMonitoringService.track_memory_usage
    end
  end

  test 'detect_memory_leaks does not raise errors' do
    assert_nothing_raised do
      MemoryMonitoringService.detect_memory_leaks
    end
  end

  test 'current memory snapshot has positive values' do
    snapshot = MemoryMonitoringService.current_memory_snapshot
    
    assert snapshot[:heap_size] > 0
    assert snapshot[:objects_allocated] > 0
    assert snapshot[:gc_count] >= 0
  end

  test 'formatted RSS is a string' do
    snapshot = MemoryMonitoringService.current_memory_snapshot
    
    assert_kind_of String, snapshot[:formatted_rss]
    assert_match(/\d+(\.\d+)?\s+(B|KB|MB|GB)/, snapshot[:formatted_rss])
  end

  test 'timestamp is a Time object' do
    snapshot = MemoryMonitoringService.current_memory_snapshot
    
    assert_kind_of Time, snapshot[:timestamp]
  end
end
