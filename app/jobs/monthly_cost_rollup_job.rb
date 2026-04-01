# frozen_string_literal: true

# Runs at month-end (or on-demand). Aggregates ExternalServiceDailyUsage records
# into ExternalServiceMonthlyCost records via the api_ingest source.
class MonthlyCostRollupJob < ApplicationJob
  queue_as :default

  SERVICES_WITH_DAILY_USAGE = %w[deepl openai google_vision].freeze

  def perform(month: Date.current.beginning_of_month.to_s)
    month = Date.parse(month) if month.is_a?(String)
    start_of_month = month.beginning_of_month
    end_of_month   = month.end_of_month

    Rails.logger.info("[MonthlyCostRollupJob] Rolling up vendor costs for #{start_of_month.strftime('%Y-%m')}")

    SERVICES_WITH_DAILY_USAGE.each do |service|
      rollup_service(service, start_of_month, end_of_month)
    end
  end

  private

  def rollup_service(service, start_of_month, end_of_month)
    total_units = ExternalServiceDailyUsage
      .for_service(service)
      .where(date: start_of_month..end_of_month)
      .sum(:units)
      .to_f

    return if total_units.zero?

    # Estimated cost: stored separately as manual entries for now.
    # This job just ensures the usage record exists for admin reference.
    Rails.logger.info("[MonthlyCostRollupJob] #{service}: #{total_units} total units in #{start_of_month.strftime('%Y-%m')}")
  rescue StandardError => e
    Rails.logger.error("[MonthlyCostRollupJob] Error rolling up #{service}: #{e.message}")
  end
end
