# frozen_string_literal: true

# Runs daily. Fetches the current Heroku space inventory and persists
# HerokuAppInventorySnapshot records for each app.
#
# Requires Flipper flag :heroku_cost_inventory to be enabled
# (or HEROKU_PLATFORM_API_TOKEN to be set) to make live API calls.
# In stub/mock mode, persists mock data for development verification.
class HerokuInventorySnapshotJob < ApplicationJob
  queue_as :default

  SPACE_NAME = 'smart-menu'

  def perform(space_name: SPACE_NAME)
    result = Heroku::SpaceInventoryService.fetch(space_name: space_name)

    if result.errors.any?
      result.errors.each do |err|
        Rails.logger.warn("[HerokuInventorySnapshotJob] Error for #{err[:app_name]}: #{err[:error]}")
      end
    end

    captured_at = Time.current
    saved_count = 0

    result.apps.each do |app_info|
      snap = HerokuAppInventorySnapshot.create!(
        captured_at: captured_at,
        space_name: space_name,
        app_id: app_info.app_id,
        app_name: app_info.app_name,
        pipeline_id: app_info.pipeline_id,
        pipeline_stage: app_info.pipeline_stage,
        environment: app_info.environment,
        formation_json: normalise_formation(app_info.formation),
        addons_json: normalise_addons(app_info.addons),
      )
      saved_count += 1 if snap.persisted?
    end

    Rails.logger.info(
      "[HerokuInventorySnapshotJob] Saved #{saved_count} snapshots " \
      "for space=#{space_name} at=#{captured_at}",
    )

    # Prune snapshots older than 90 days
    prune_old_snapshots(space_name)

    saved_count
  end

  private

  def normalise_formation(formation)
    Array(formation).map do |f|
      {
        'type' => f['type'] || f[:type],
        'size' => f['size'] || f[:size],
        'quantity' => (f['quantity'] || f[:quantity]).to_i,
      }
    end
  end

  def normalise_addons(addons)
    Array(addons).map do |a|
      {
        'addon_service' => { 'name' => a.dig('addon_service', 'name') || a.dig(:addon_service, :name) },
        'plan' => { 'name' => a.dig('plan', 'name') || a.dig(:plan, :name) },
      }
    end
  end

  def prune_old_snapshots(space_name)
    cutoff = 90.days.ago
    deleted = HerokuAppInventorySnapshot.for_space(space_name).where(captured_at: ...cutoff).delete_all
    Rails.logger.info("[HerokuInventorySnapshotJob] Pruned #{deleted} old snapshots") if deleted.positive?
  end
end
