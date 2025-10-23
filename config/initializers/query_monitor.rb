# frozen_string_literal: true

# Query monitoring for development and test environments
# Logs slow queries to help identify performance bottlenecks
if Rails.env.development? || Rails.env.test?
  # Track query counts and slow queries
  ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    
    # Skip schema queries and CACHE hits
    next if event.payload[:name] == 'SCHEMA' || event.payload[:name] == 'CACHE'
    
    # Log slow queries (> 50ms)
    if event.duration > 50
      Rails.logger.warn(
        "⚠️  Slow Query (#{event.duration.round(2)}ms): " \
        "#{event.payload[:sql].truncate(200)}"
      )
    end
    
    # Log very slow queries (> 100ms) with full SQL
    if event.duration > 100
      Rails.logger.error(
        "🔴 Very Slow Query (#{event.duration.round(2)}ms):\n" \
        "SQL: #{event.payload[:sql]}\n" \
        "Binds: #{event.payload[:type_casted_binds]}"
      )
    end
  end
  
  # Track N+1 queries in development
  if Rails.env.development?
    require 'active_support/notifications'
    
    # Simple N+1 detection
    query_counts = Hash.new(0)
    
    ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      
      # Skip schema and cache
      next if event.payload[:name] == 'SCHEMA' || event.payload[:name] == 'CACHE'
      
      # Track similar queries
      sql_pattern = event.payload[:sql].gsub(/\d+/, 'N').gsub(/'[^']*'/, '?')
      query_counts[sql_pattern] += 1
      
      # Warn if same query pattern executed many times
      if query_counts[sql_pattern] == 10
        Rails.logger.warn(
          "⚠️  Possible N+1 Query Detected:\n" \
          "Pattern: #{sql_pattern.truncate(200)}\n" \
          "Executed 10+ times"
        )
      end
    end
    
    # Reset counts periodically
    Thread.new do
      loop do
        sleep 60
        query_counts.clear
      end
    end
  end
  
  Rails.logger.info("✅ Query monitoring enabled (slow query threshold: 50ms)")
end
