# frozen_string_literal: true

# Background job for importing a web menu source.
# Scrapes the HTML page, processes through GPT, and saves structured menu data.
# Replaces the synchronous work previously done in
# OcrMenuImportsController#import_from_web_menu_source to avoid Heroku H12 timeouts.
class WebMenuSourceImportJob < ApplicationJob
  queue_as :default

  def perform(ocr_menu_import_id:, menu_source_id:)
    import = OcrMenuImport.find_by(id: ocr_menu_import_id)
    return if import.nil?

    menu_source = MenuSource.find_by(id: menu_source_id)
    unless menu_source&.html? && menu_source&.source_url.present?
      import.update!(
        status: 'failed',
        error_message: 'Not a valid web menu source',
        metadata: (import.metadata || {}).merge('phase' => 'failed'),
      )
      return
    end

    # Scrape the HTML page(s)
    scraper = MenuDiscovery::WebMenuScraper.new
    scrape_result = scraper.scrape([{ url: menu_source.source_url, html: nil }])

    if scrape_result[:menu_text].blank?
      import.update!(
        status: 'failed',
        error_message: 'Could not extract menu text from the web page',
        metadata: (import.metadata || {}).merge('phase' => 'failed'),
      )
      return
    end

    import.update!(
      metadata: (import.metadata || {}).merge(
        'source_urls' => scrape_result[:source_urls],
        'phase' => 'processing',
      ),
    )

    import.process!
    processor = WebMenuProcessor.new(import)
    processor.process(
      menu_text: scrape_result[:menu_text],
      source_urls: scrape_result[:source_urls],
    )
    import.complete!

    Rails.logger.info "[WebMenuSourceImportJob] Completed import ##{import.id} for MenuSource ##{menu_source_id}"
  rescue StandardError => e
    Rails.logger.error "[WebMenuSourceImportJob] Failed import ##{ocr_menu_import_id}: #{e.class}: #{e.message}"
    import = OcrMenuImport.find_by(id: ocr_menu_import_id)
    if import
      begin
        import.fail!(e.message)
      rescue StandardError
        import.update_columns(status: 'failed', error_message: e.message)
      end
    end
  end
end
