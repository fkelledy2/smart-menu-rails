# frozen_string_literal: true

# Runs daily. Polls the DeepL usage API and stores ExternalServiceDailyUsage records.
class DeeplUsageIngestionJob < ApplicationJob
  queue_as :default

  def perform(date: Date.yesterday.to_s)
    date = Date.parse(date) if date.is_a?(String)

    result = VendorUsage::DeeplIngestionService.ingest(date: date)

    if result.success?
      Rails.logger.info(
        "[DeeplUsageIngestionJob] Ingested DeepL usage for #{date}: #{result.usage.inspect}",
      )
    else
      Rails.logger.warn("[DeeplUsageIngestionJob] Failed for #{date}: #{result.error}")
    end
  end
end
