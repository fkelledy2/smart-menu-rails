class MaterializedViewService
  include Singleton

  class << self
    delegate_missing_to :instance
  end

  # Available materialized views with their refresh frequencies
  MATERIALIZED_VIEWS = {
    'restaurant_analytics_mv' => { frequency: 15.minutes, priority: :high },
    'menu_performance_mv' => { frequency: 30.minutes, priority: :medium },
    'system_analytics_mv' => { frequency: 1.hour, priority: :low },
    'dw_orders_mv' => { frequency: 1.hour, priority: :medium }, # Existing view
  }.freeze

  # Refresh a specific materialized view
  def refresh_view(view_name, concurrently: true)
    validate_view_name!(view_name)

    start_time = Time.current
    Rails.logger.info "[MaterializedViewService] Starting refresh of #{view_name}"

    begin
      refresh_sql = if concurrently && supports_concurrent_refresh?(view_name)
                      "REFRESH MATERIALIZED VIEW CONCURRENTLY #{view_name};"
                    else
                      "REFRESH MATERIALIZED VIEW #{view_name};"
                    end

      ActiveRecord::Base.connection.execute(refresh_sql)

      duration = Time.current - start_time
      Rails.logger.info "[MaterializedViewService] Successfully refreshed #{view_name} in #{duration.round(2)}s"

      # Track refresh metrics
      track_refresh_metrics(view_name, duration, :success)

      { success: true, duration: duration, view: view_name }
    rescue StandardError => e
      duration = Time.current - start_time
      Rails.logger.error "[MaterializedViewService] Failed to refresh #{view_name}: #{e.message}"

      # Track failure metrics
      track_refresh_metrics(view_name, duration, :failure, e.message)

      { success: false, duration: duration, view: view_name, error: e.message }
    end
  end

  # Refresh all materialized views
  def refresh_all_views(concurrently: true)
    results = {}

    MATERIALIZED_VIEWS.each_key do |view_name|
      results[view_name] = refresh_view(view_name, concurrently: concurrently)
    end

    results
  end

  # Refresh views by priority level
  def refresh_by_priority(priority_level, concurrently: true)
    views_to_refresh = MATERIALIZED_VIEWS.select { |_, config| config[:priority] == priority_level }
    results = {}

    views_to_refresh.each_key do |view_name|
      results[view_name] = refresh_view(view_name, concurrently: concurrently)
    end

    results
  end

  # Check if views need refreshing based on their frequency
  def views_needing_refresh
    needing_refresh = []

    MATERIALIZED_VIEWS.each do |view_name, config|
      last_refresh = get_last_refresh_time(view_name)
      next_refresh = last_refresh + config[:frequency]

      next unless Time.current >= next_refresh

      needing_refresh << {
        view: view_name,
        last_refresh: last_refresh,
        frequency: config[:frequency],
        overdue_by: Time.current - next_refresh,
      }
    end

    needing_refresh
  end

  # Get materialized view statistics
  def view_statistics(view_name = nil)
    if view_name
      validate_view_name!(view_name)
      get_single_view_stats(view_name)
    else
      MATERIALIZED_VIEWS.keys.map { |name| get_single_view_stats(name) }
    end
  end

  # Health check for all materialized views
  def health_check
    results = {
      overall_status: :healthy,
      views: {},
      summary: {
        total_views: MATERIALIZED_VIEWS.size,
        healthy_views: 0,
        stale_views: 0,
        failed_views: 0,
      },
    }

    MATERIALIZED_VIEWS.each do |view_name, config|
      view_health = check_view_health(view_name, config)
      results[:views][view_name] = view_health

      case view_health[:status]
      when :healthy
        results[:summary][:healthy_views] += 1
      when :stale
        results[:summary][:stale_views] += 1
        results[:overall_status] = :degraded if results[:overall_status] == :healthy
      when :failed
        results[:summary][:failed_views] += 1
        results[:overall_status] = :unhealthy
      end
    end

    results
  end

  private

  def validate_view_name!(view_name)
    unless MATERIALIZED_VIEWS.key?(view_name)
      raise ArgumentError,
            "Unknown materialized view: #{view_name}. Available views: #{MATERIALIZED_VIEWS.keys.join(', ')}"
    end
  end

  def supports_concurrent_refresh?(view_name)
    # Concurrent refresh requires unique indexes
    # For now, we'll be conservative and only use concurrent refresh for specific views
    %w[restaurant_analytics_mv menu_performance_mv].include?(view_name)
  end

  def get_last_refresh_time(view_name)
    # Query PostgreSQL system catalogs for last refresh time
    result = ActiveRecord::Base.connection.execute(<<~SQL.squish)
      SELECT#{' '}
        schemaname,
        matviewname,
        hasindexes,
        ispopulated,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||matviewname)) as size
      FROM pg_matviews#{' '}
      WHERE matviewname = '#{view_name}';
    SQL

    if result.any?
      # If we can't get exact refresh time, use a conservative estimate
      # In production, you might want to track this in a separate table
      1.hour.ago
    else
      1.day.ago # Very stale if view doesn't exist
    end
  end

  def get_single_view_stats(view_name)
    result = ActiveRecord::Base.connection.execute(<<~SQL.squish)
      SELECT#{' '}
        schemaname,
        matviewname,
        hasindexes,
        ispopulated,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||matviewname)) as size,
        pg_total_relation_size(schemaname||'.'||matviewname) as size_bytes
      FROM pg_matviews#{' '}
      WHERE matviewname = '#{view_name}';
    SQL

    if result.any?
      row = result.first
      {
        name: view_name,
        schema: row['schemaname'],
        has_indexes: row['hasindexes'],
        is_populated: row['ispopulated'],
        size: row['size'],
        size_bytes: row['size_bytes'].to_i,
        last_refresh: get_last_refresh_time(view_name),
        frequency: MATERIALIZED_VIEWS[view_name][:frequency],
        priority: MATERIALIZED_VIEWS[view_name][:priority],
      }
    else
      {
        name: view_name,
        error: 'View not found',
        exists: false,
      }
    end
  end

  def check_view_health(view_name, config)
    stats = get_single_view_stats(view_name)

    return { status: :failed, reason: 'View not found' } unless stats[:exists] != false

    last_refresh = stats[:last_refresh]
    staleness = Time.current - last_refresh
    max_staleness = config[:frequency] * 2 # Allow 2x the frequency before marking as stale

    if staleness > max_staleness
      {
        status: :stale,
        reason: "Last refreshed #{staleness.round(0)}s ago (max: #{max_staleness.round(0)}s)",
        staleness: staleness,
        max_staleness: max_staleness,
      }
    else
      {
        status: :healthy,
        last_refresh: last_refresh,
        staleness: staleness,
      }
    end
  end

  def track_refresh_metrics(view_name, duration, status, error_message = nil)
    # In a production environment, you might want to send these metrics to your monitoring system
    # For now, we'll just log them

    Rails.logger.info "[MaterializedViewService] Refresh metrics: view=#{view_name}, duration=#{duration.round(2)}s, status=#{status}"

    if error_message
      Rails.logger.error "[MaterializedViewService] Refresh error: view=#{view_name}, error=#{error_message}"
    end

    # You could also store these metrics in a database table for historical analysis
    # RefreshMetric.create!(
    #   view_name: view_name,
    #   duration: duration,
    #   status: status,
    #   error_message: error_message,
    #   refreshed_at: Time.current
    # )
  end
end
