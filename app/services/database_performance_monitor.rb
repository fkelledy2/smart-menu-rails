class DatabasePerformanceMonitor
  SLOW_QUERY_THRESHOLD = Rails.env.production? ? 100 : 50 # milliseconds

  def self.setup_monitoring
    return unless Rails.application.config.respond_to?(:enable_apm) && Rails.application.config.enable_apm

    ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, start, finish, _id, payload|
      duration = (finish - start) * 1000 # Convert to ms

      # Skip very fast queries to reduce noise
      next if duration < 10

      # Log slow queries
      if duration > slow_query_threshold
        log_slow_query(payload[:sql], duration, payload[:name], payload[:connection])
      end

      # Track query patterns for analysis
      track_query_patterns(payload[:sql], duration)
    end
  end

  def self.slow_query_threshold
    Rails.application.config.slow_query_threshold || SLOW_QUERY_THRESHOLD
  end

  def self.log_slow_query(sql, duration, name, _connection)
    # Skip schema queries and internal Rails queries
    return if skip_query?(sql, name)

    # Create slow query record asynchronously
    SlowQueryTrackingJob.perform_later(
      sql: sql,
      duration: duration,
      query_name: name,
      timestamp: Time.current,
      backtrace: extract_relevant_backtrace,
    )
  end

  def self.track_query_patterns(sql, duration)
    # Track query patterns for N+1 detection
    pattern = normalize_sql_pattern(sql)

    # Store in Redis for real-time analysis
    return unless defined?(Redis) && Rails.cache.respond_to?(:redis)

    key = "query_pattern:#{pattern}"
    Rails.cache.increment(key, 1)
    Rails.cache.expire(key, 5.minutes)

    # Check for potential N+1 queries
    count = Rails.cache.read(key) || 0
    if count > 10 # More than 10 similar queries in 5 minutes
      detect_n_plus_one(pattern, count, duration)
    end
  end

  def self.skip_query?(sql, name)
    # Skip schema queries
    return true if name&.include?('SCHEMA')

    # Skip internal Rails queries
    return true if sql.include?('schema_migrations')
    return true if sql.include?('ar_internal_metadata')

    # Skip EXPLAIN queries
    return true if sql.upcase.start_with?('EXPLAIN')

    # Skip transaction queries
    return true if sql.match?(/^(BEGIN|COMMIT|ROLLBACK)/i)

    false
  end

  def self.normalize_sql_pattern(sql)
    # Normalize SQL for pattern matching
    sql.gsub(/\$\d+/, '?') # Replace $1, $2, etc. with ?
      .gsub(/\b\d+\b/, '?')                  # Replace numbers with ?
      .gsub(/'[^']*'/, '?')                  # Replace string literals with ?
      .gsub(/\s+/, ' ')                      # Normalize whitespace
      .strip
      .truncate(200)                         # Limit length
  end

  def self.detect_n_plus_one(pattern, count, duration)
    # Alert if we detect potential N+1 queries
    return unless count > 20 && duration < 100 # Many fast queries of same pattern

    PerformanceAlertJob.perform_later(
      type: 'n_plus_one',
      pattern: pattern,
      count: count,
      avg_duration: duration,
      severity: 'medium',
    )
  end

  def self.extract_relevant_backtrace
    # Extract only application-relevant backtrace lines
    caller.select { |line| line.include?(Rails.root.to_s) }
      .reject { |line| line.include?('vendor/bundle') }
      .first(10)
  end
end
