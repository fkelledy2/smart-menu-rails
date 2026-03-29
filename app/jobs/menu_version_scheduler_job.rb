class MenuVersionSchedulerJob < ApplicationJob
  queue_as :default

  # Runs periodically (every 5 minutes via cron) to activate/deactivate menu versions
  # that have a scheduled starts_at or ends_at time.
  #
  # MenuVersionActivationService.activate! with starts_at/ends_at stores the intent but
  # marks is_active: false — this job is what actually applies the schedule.
  def perform
    now = Time.current

    # Activate versions whose starts_at has arrived and are not yet active.
    activatable = MenuVersion
      .where(is_active: false)
      .where(starts_at: ..now)
      .where('ends_at IS NULL OR ends_at > ?', now)

    activatable.find_each do |version|
      menu = version.menu
      menu.with_lock do
        # Deactivate any currently active version for this menu.
        MenuVersion
          .where(menu_id: menu.id, is_active: true)
          .where.not(id: version.id)
          .update_all(is_active: false)

        version.update!(is_active: true)
        Rails.logger.info(
          "[MenuVersionSchedulerJob] Activated version #{version.id} (v#{version.version_number}) " \
          "for menu #{menu.id} at #{now}",
        )
      end
    rescue StandardError => e
      Rails.logger.error(
        "[MenuVersionSchedulerJob] Failed to activate version #{version.id}: #{e.class}: #{e.message}",
      )
    end

    # Deactivate versions whose ends_at has passed.
    expirable = MenuVersion
      .where(is_active: true)
      .where('ends_at IS NOT NULL AND ends_at <= ?', now)

    expirable.find_each do |version|
      version.update!(is_active: false)
      Rails.logger.info(
        "[MenuVersionSchedulerJob] Deactivated expired version #{version.id} " \
        "(v#{version.version_number}) for menu #{version.menu_id} at #{now}",
      )
    rescue StandardError => e
      Rails.logger.error(
        "[MenuVersionSchedulerJob] Failed to deactivate version #{version.id}: #{e.class}: #{e.message}",
      )
    end
  end
end
