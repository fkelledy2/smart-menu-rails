# frozen_string_literal: true

module QueryMonitoring
  extend ActiveSupport::Concern

  included do
    # Subscribe to SQL queries
    ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
      # Skip schema queries and internal Rails queries
      next if payload[:name]&.include?('SCHEMA')
      next if payload[:sql]&.include?('sqlite_master')
      next if payload[:sql]&.include?('PRAGMA')
      
      duration = (finish - start) * 1000 # Convert to milliseconds
      
      PerformanceMonitoringService.track_query(
        sql: payload[:sql],
        duration: duration,
        name: payload[:name]
      )
    end

    # Subscribe to cache operations
    ActiveSupport::Notifications.subscribe('cache_read.active_support') do |name, start, finish, id, payload|
      if payload[:hit]
        PerformanceMonitoringService.track_cache_hit
      else
        PerformanceMonitoringService.track_cache_miss
      end
    end

    ActiveSupport::Notifications.subscribe('cache_fetch_hit.active_support') do |name, start, finish, id, payload|
      PerformanceMonitoringService.track_cache_hit
    end

    ActiveSupport::Notifications.subscribe('cache_generate.active_support') do |name, start, finish, id, payload|
      PerformanceMonitoringService.track_cache_miss
    end
  end

  class_methods do
    # Monitor specific queries
    def with_query_monitoring(description = nil)
      start_time = Time.current
      result = yield
      duration = (Time.current - start_time) * 1000
      
      PerformanceMonitoringService.track_query(
        sql: description || 'Custom Query Block',
        duration: duration,
        name: "#{self.name}##{caller_locations(1, 1).first.label}"
      )
      
      result
    end
  end

  # Instance method for monitoring queries
  def with_query_monitoring(description = nil)
    self.class.with_query_monitoring(description) { yield }
  end
end

# Include in ApplicationRecord
if defined?(ApplicationRecord)
  ApplicationRecord.include QueryMonitoring
end
