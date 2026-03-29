# frozen_string_literal: true

class Menu::RefreshEnrichmentsJob
  include Sidekiq::Job

  sidekiq_options queue: 'low', retry: 2

  # Scheduled job to refresh stale product enrichments.
  # Finds enrichments past their expires_at and re-enriches.
  # Intended to run via Sidekiq-Cron or similar scheduler (e.g. weekly).
  def perform(batch_size = 50)
    # Load the batch IDs up-front so we have a stable, size-capped set.
    # find_each silently ignores .limit, so we pluck the IDs first and then
    # iterate over that fixed array — this also captures the correct total for logging.
    stale_ids = ProductEnrichment
      .where(expires_at: ...Time.current)
      .order(expires_at: :asc)
      .limit(batch_size)
      .pluck(:id)

    total = stale_ids.size
    refreshed = 0

    stale_ids.each do |enrichment_id|
      enrichment = ProductEnrichment.includes(:product).find_by(id: enrichment_id)
      product = enrichment&.product
      next unless product

      enrich_job = Menu::EnrichProductsJob.new
      enrich_job.send(:ensure_product_enrichment!, product)
      refreshed += 1
    rescue StandardError => e
      Rails.logger.warn("[RefreshEnrichmentsJob] Failed for product ##{product&.id}: #{e.class}: #{e.message}")
    end

    Rails.logger.info("[RefreshEnrichmentsJob] Refreshed #{refreshed}/#{total} enrichments")
    refreshed
  end
end
