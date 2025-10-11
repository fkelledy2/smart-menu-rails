class DatabaseRoutingService
  class << self
    # Execute analytics queries on replica with automatic fallback
    def with_analytics_connection(&)
      ApplicationRecord.on_replica do
        Rails.logger.debug 'Executing analytics query on read replica'
        yield
      end
    rescue StandardError => e
      Rails.logger.error "Analytics query failed on replica: #{e.message}"
      ApplicationRecord.on_primary(&)
    end

    # Execute read-heavy queries on replica
    def with_read_connection(&)
      if replica_healthy?
        ApplicationRecord.on_replica(&)
      else
        Rails.logger.warn 'Read replica unhealthy, using primary'
        ApplicationRecord.on_primary(&)
      end
    end

    # Force execution on primary (for consistency-critical reads)
    def with_primary_connection(&)
      ApplicationRecord.on_primary(&)
    end

    # Check replica health and lag
    def replica_healthy?
      return true unless Rails.env.production?

      @replica_health_cache ||= {}
      cache_key = "replica_health_#{Time.current.to_i / 30}" # 30-second cache

      @replica_health_cache[cache_key] ||= begin
        check_replica_health
      rescue StandardError => e
        Rails.logger.error "Failed to check replica health: #{e.message}"
        false
      end
    end

    # Get replica lag in seconds
    def replica_lag
      ApplicationRecord.on_primary do
        result = ApplicationRecord.connection.execute(<<~SQL.squish)
          SELECT#{' '}
            COALESCE(
              EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp())),#{' '}
              0
            ) AS lag_seconds
        SQL
        result.first['lag_seconds'].to_f
      end
    rescue StandardError => e
      Rails.logger.error "Failed to get replica lag: #{e.message}"
      Float::INFINITY
    end

    # Get connection statistics for monitoring
    def connection_stats
      stats = {}

      # Primary connection stats
      begin
        primary_pool = ActiveRecord::Base.connection_handler.retrieve_connection_pool('primary')
        if primary_pool.respond_to?(:stat)
          primary_stat = primary_pool.stat
          stats[:primary] = {
            size: primary_stat[:size],
            busy: primary_stat[:busy],
            available: primary_stat[:size] - primary_stat[:busy],
            utilization: (primary_stat[:busy].to_f / primary_stat[:size] * 100).round(2),
          }
        end
      rescue StandardError => e
        Rails.logger.error "Failed to get primary connection stats: #{e.message}"
        stats[:primary] = { error: e.message }
      end

      # Replica connection stats
      begin
        replica_pool = ActiveRecord::Base.connection_handler.retrieve_connection_pool('replica')
        if replica_pool.respond_to?(:stat)
          replica_stat = replica_pool.stat
          stats[:replica] = {
            size: replica_stat[:size],
            busy: replica_stat[:busy],
            available: replica_stat[:size] - replica_stat[:busy],
            utilization: (replica_stat[:busy].to_f / replica_stat[:size] * 100).round(2),
          }
        end
      rescue StandardError => e
        Rails.logger.error "Failed to get replica connection stats: #{e.message}"
        stats[:replica] = { error: e.message }
      end

      stats[:replica_lag] = replica_lag
      stats[:replica_healthy] = replica_healthy?

      stats
    end

    # Route query based on type and consistency requirements
    def route_query(query_type: :read, consistency: :eventual, &)
      case query_type
      when :analytics, :reporting
        with_analytics_connection(&)
      when :read
        case consistency
        when :strong, :immediate
          with_primary_connection(&)
        when :eventual, :weak
          with_read_connection(&)
        else
          with_read_connection(&)
        end
      when :write, :transaction
        with_primary_connection(&)
      else
        with_read_connection(&)
      end
    end

    private

    def check_replica_health
      # Check if replica connection is available
      ApplicationRecord.on_replica do
        ApplicationRecord.connection.execute('SELECT 1')
      end

      # Check replica lag
      lag = replica_lag
      if lag > 5.0 # 5 seconds max acceptable lag
        Rails.logger.warn "Replica lag too high: #{lag} seconds"
        return false
      end

      true
    rescue StandardError => e
      Rails.logger.error "Replica health check failed: #{e.message}"
      false
    end
  end
end
