# frozen_string_literal: true

# Runs at month-end or on-demand from the admin UI.
# Computes infra cost totals from snapshots and persists InfraCostSnapshot records.
class HerokuMonthlyCostRollupJob < ApplicationJob
  queue_as :default

  SPACE_NAME = 'smart-menu'

  def perform(month: Date.current.beginning_of_month, space_name: SPACE_NAME, created_by_user_id: nil)
    month = Date.parse(month) if month.is_a?(String)

    Rails.logger.info("[HerokuMonthlyCostRollupJob] Rolling up month=#{month} space=#{space_name}")

    result = Heroku::CostRollupService.rollup(
      month: month,
      space_name: space_name,
      created_by_user_id: created_by_user_id,
    )

    if result.success?
      Rails.logger.info(
        "[HerokuMonthlyCostRollupJob] Saved #{result.snapshots.size} cost snapshots",
      )
    else
      result.errors.each { |e| Rails.logger.warn("[HerokuMonthlyCostRollupJob] #{e}") }
    end

    result
  end
end
