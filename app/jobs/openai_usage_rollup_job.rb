# frozen_string_literal: true

# Runs daily. Rolls up Redis-accumulated OpenAI usage counters
# into ExternalServiceDailyUsage records.
class OpenaiUsageRollupJob < ApplicationJob
  queue_as :default

  def perform(date: Date.yesterday.to_s)
    date = Date.parse(date) if date.is_a?(String)

    VendorUsage::OpenaiMeteringService.rollup(date: date)

    Rails.logger.info("[OpenaiUsageRollupJob] Rolled up OpenAI usage for #{date}")
  end
end
