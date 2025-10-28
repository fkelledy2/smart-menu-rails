class MaterializedViewRefreshJob < ApplicationJob
  queue_as :default

  # Retry configuration for reliability
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  discard_on ArgumentError # Don't retry invalid view names

  def perform(view_name = nil, priority_level = nil, force_refresh = false)
    Rails.logger.info '[MaterializedViewRefreshJob] Starting refresh job'

    if view_name
      # Refresh a specific view
      refresh_specific_view(view_name, force_refresh)
    elsif priority_level
      # Refresh views by priority level
      refresh_by_priority(priority_level)
    else
      # Refresh views that need updating based on their frequency
      refresh_stale_views
    end
  end

  private

  def refresh_specific_view(view_name, _force_refresh)
    Rails.logger.info "[MaterializedViewRefreshJob] Refreshing specific view: #{view_name}"

    result = MaterializedViewService.refresh_view(view_name, concurrently: true)

    if result[:success]
      Rails.logger.info "[MaterializedViewRefreshJob] Successfully refreshed #{view_name} in #{result[:duration].round(2)}s"
    else
      Rails.logger.error "[MaterializedViewRefreshJob] Failed to refresh #{view_name}: #{result[:error]}"
      raise StandardError, "Failed to refresh #{view_name}: #{result[:error]}"
    end
  end

  def refresh_by_priority(priority_level)
    Rails.logger.info "[MaterializedViewRefreshJob] Refreshing views with priority: #{priority_level}"

    results = MaterializedViewService.refresh_by_priority(priority_level.to_sym, concurrently: true)

    success_count = results.count { |_, result| result[:success] }
    total_count = results.size

    Rails.logger.info "[MaterializedViewRefreshJob] Refreshed #{success_count}/#{total_count} #{priority_level} priority views"

    # Log any failures
    results.each do |view_name, result|
      unless result[:success]
        Rails.logger.error "[MaterializedViewRefreshJob] Failed to refresh #{view_name}: #{result[:error]}"
      end
    end

    # Raise error if any critical views failed
    if priority_level.to_sym == :high && success_count < total_count
      failed_views = results.reject { |_, result| result[:success] }.keys
      raise StandardError, "Critical view refresh failures: #{failed_views.join(', ')}"
    end
  end

  def refresh_stale_views
    Rails.logger.info '[MaterializedViewRefreshJob] Checking for stale views'

    stale_views = MaterializedViewService.views_needing_refresh

    if stale_views.empty?
      Rails.logger.info '[MaterializedViewRefreshJob] No views need refreshing'
      return
    end

    Rails.logger.info "[MaterializedViewRefreshJob] Found #{stale_views.size} stale views: #{stale_views.pluck(:view).join(', ')}"

    results = []
    stale_views.each do |view_info|
      view_name = view_info[:view]
      overdue_by = view_info[:overdue_by]

      Rails.logger.info "[MaterializedViewRefreshJob] Refreshing #{view_name} (overdue by #{overdue_by.round(0)}s)"

      result = MaterializedViewService.refresh_view(view_name, concurrently: true)
      results << { view: view_name, result: result }

      if result[:success]
        Rails.logger.info "[MaterializedViewRefreshJob] Successfully refreshed #{view_name}"
      else
        Rails.logger.error "[MaterializedViewRefreshJob] Failed to refresh #{view_name}: #{result[:error]}"
      end
    end

    # Summary logging
    success_count = results.count { |r| r[:result][:success] }
    Rails.logger.info "[MaterializedViewRefreshJob] Refresh summary: #{success_count}/#{results.size} views refreshed successfully"

    # Alert on failures for high-priority views
    failed_high_priority = results.select do |r|
      !r[:result][:success] &&
        MaterializedViewService::MATERIALIZED_VIEWS[r[:view]][:priority] == :high
    end

    return unless failed_high_priority.any?

    failed_view_names = failed_high_priority.pluck(:view)
    Rails.logger.error "[MaterializedViewRefreshJob] High-priority view refresh failures: #{failed_view_names.join(', ')}"

    # In production, you might want to send alerts here
    # AlertService.send_alert("High-priority materialized view refresh failures", failed_view_names)
  end
end
