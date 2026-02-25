# frozen_string_literal: true

# Regenerates the XML sitemap and pings search engines.
# Scheduled nightly via Sidekiq cron at 3am UTC.
class SitemapGeneratorJob < ApplicationJob
  queue_as :low

  def perform
    SitemapGenerator::Interpreter.run
    SitemapGenerator::Sitemap.ping_search_engines
    Rails.logger.info('[SitemapGeneratorJob] Sitemap regenerated and search engines pinged')
  end
end
