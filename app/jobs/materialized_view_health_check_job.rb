class MaterializedViewHealthCheckJob < ApplicationJob
  queue_as :default

  # Don't retry health checks - they should be lightweight
  discard_on StandardError

  def perform
    Rails.logger.info '[MaterializedViewHealthCheckJob] Starting health check'

    health_check = MaterializedViewService.health_check

    log_health_summary(health_check)

    # Alert on unhealthy status
    if health_check[:overall_status] != :healthy
      handle_unhealthy_views(health_check)
    end

    # Store health metrics for monitoring
    store_health_metrics(health_check)

    Rails.logger.info '[MaterializedViewHealthCheckJob] Health check completed'
  end

  private

  def log_health_summary(health_check)
    summary = health_check[:summary]
    status = health_check[:overall_status]

    Rails.logger.info "[MaterializedViewHealthCheckJob] Overall status: #{status}"
    Rails.logger.info "[MaterializedViewHealthCheckJob] Views: #{summary[:healthy_views]} healthy, #{summary[:stale_views]} stale, #{summary[:failed_views]} failed"

    # Log details for problematic views
    health_check[:views].each do |view_name, view_health|
      next if view_health[:status] == :healthy

      Rails.logger.warn "[MaterializedViewHealthCheckJob] #{view_name}: #{view_health[:status]} - #{view_health[:reason]}"
    end
  end

  def handle_unhealthy_views(health_check)
    case health_check[:overall_status]
    when :degraded
      handle_degraded_views(health_check)
    when :unhealthy
      handle_failed_views(health_check)
    end
  end

  def handle_degraded_views(health_check)
    stale_views = health_check[:views].select { |_, health| health[:status] == :stale }

    Rails.logger.warn "[MaterializedViewHealthCheckJob] Found #{stale_views.size} stale views"

    # Trigger refresh for stale high-priority views
    stale_views.each_key do |view_name|
      view_config = MaterializedViewService::MATERIALIZED_VIEWS[view_name]

      if view_config && view_config[:priority] == :high
        Rails.logger.info "[MaterializedViewHealthCheckJob] Triggering emergency refresh for high-priority view: #{view_name}"
        MaterializedViewRefreshJob.perform_later(view_name, nil, true)
      end
    end
  end

  def handle_failed_views(health_check)
    failed_views = health_check[:views].select { |_, health| health[:status] == :failed }

    Rails.logger.error "[MaterializedViewHealthCheckJob] Found #{failed_views.size} failed views: #{failed_views.keys.join(', ')}"

    # In production, you might want to send alerts here
    # AlertService.send_critical_alert(
    #   "Materialized View Failures",
    #   "Failed views: #{failed_views.keys.join(', ')}"
    # )

    # Attempt to recreate failed views (this would need additional logic)
    # For now, just log the issue
    failed_views.each do |view_name, health|
      Rails.logger.error "[MaterializedViewHealthCheckJob] #{view_name} failed: #{health[:reason]}"
    end
  end

  def store_health_metrics(health_check)
    # Store metrics for historical analysis
    # In a production environment, you might store these in a monitoring database
    # or send them to your metrics collection system

    timestamp = Time.current

    Rails.logger.debug { "[MaterializedViewHealthCheckJob] Storing health metrics for #{timestamp}" }

    # Example: Store in Rails cache for short-term monitoring
    Rails.cache.write(
      "materialized_view_health:#{timestamp.to_i}",
      {
        timestamp: timestamp,
        overall_status: health_check[:overall_status],
        summary: health_check[:summary],
        view_details: health_check[:views],
      },
      expires_in: 24.hours,
    )

    # Keep only the last 24 health checks in cache
    cleanup_old_health_metrics
  end

  def cleanup_old_health_metrics
    # Clean up old health check data from cache
    24.hours.ago.to_i

    # This is a simplified cleanup - in production you might use a more sophisticated approach
    Rails.logger.debug { "[MaterializedViewHealthCheckJob] Cleaning up health metrics older than #{24.hours.ago}" }

    # NOTE: This is just an example - Rails.cache doesn't have a built-in way to list keys
    # In production, you might use Redis directly or store metrics in a database
  end
end
