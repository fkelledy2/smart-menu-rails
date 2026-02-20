# frozen_string_literal: true

class Menu::RefreshEnrichmentsJob
  include Sidekiq::Job

  sidekiq_options queue: 'low', retry: 2

  # Scheduled job to refresh stale product enrichments.
  # Finds enrichments past their expires_at and re-enriches.
  # Intended to run via Sidekiq-Cron or similar scheduler (e.g. weekly).
  def perform(batch_size = 50)
    stale = ProductEnrichment
      .where('expires_at < ?', Time.current)
      .order(expires_at: :asc)
      .limit(batch_size)
      .includes(:product)

    refreshed = 0
    stale.find_each do |enrichment|
      product = enrichment.product
      next unless product

      enrich_job = Menu::EnrichProductsJob.new
      enrich_job.send(:ensure_product_enrichment!, product)
      refreshed += 1
    rescue StandardError => e
      Rails.logger.warn("[RefreshEnrichmentsJob] Failed for product ##{product&.id}: #{e.class}: #{e.message}")
    end

    Rails.logger.info("[RefreshEnrichmentsJob] Refreshed #{refreshed}/#{stale.count} enrichments")
    refreshed
  end
end
