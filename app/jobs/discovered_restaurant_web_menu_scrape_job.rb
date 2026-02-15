class DiscoveredRestaurantWebMenuScrapeJob < ApplicationJob
  queue_as :default

  # Orchestrates: find HTML menu pages → scrape text → GPT parse → save as OcrMenuImport
  def perform(discovered_restaurant_id:, triggered_by_user_id: nil)
    dr = DiscoveredRestaurant.find_by(id: discovered_restaurant_id)
    return if dr.nil?

    base_url = dr.website_url.to_s.strip
    if base_url.blank?
      update_status!(dr, 'failed', error: 'No website URL')
      return
    end

    update_status!(dr, 'scraping')

    robots_checker = MenuDiscovery::RobotsTxtChecker.new
    finder = MenuDiscovery::WebsiteMenuFinder.new(base_url: base_url, robots_checker: robots_checker)

    result = finder.find_menus(max_pages: 15)
    html_pages = result[:html_menu_pages]
    pdf_urls = result[:pdfs]

    # Record what was found
    update_metadata!(dr, {
      'web_menu_scrape' => {
        'status' => 'processing',
        'html_pages_found' => html_pages.size,
        'pdf_urls_found' => pdf_urls.size,
        'triggered_by_user_id' => triggered_by_user_id,
        'started_at' => Time.current.iso8601,
      },
    })

    # Store discovered PDF URLs as MenuSource records (for later PDF import)
    pdf_urls.each do |pdf_url|
      next if dr.menu_sources.exists?(source_url: pdf_url)

      dr.menu_sources.create!(
        source_url: pdf_url,
        source_type: :pdf,
        status: :active,
      )
    rescue StandardError => e
      Rails.logger.warn "WebMenuScrapeJob: failed to create PDF MenuSource: #{e.message}"
    end

    if html_pages.empty?
      update_status!(dr, 'completed', details: {
        'html_pages_found' => 0,
        'pdf_urls_found' => pdf_urls.size,
        'message' => pdf_urls.any? ? 'No HTML menus found, but PDF menu URLs discovered' : 'No menu content found on website',
      })
      return
    end

    # Scrape clean text from HTML menu pages
    scraper = MenuDiscovery::WebMenuScraper.new(robots_checker: robots_checker)
    scrape_result = scraper.scrape(html_pages)

    if scrape_result[:menu_text].blank?
      update_status!(dr, 'completed', details: {
        'html_pages_found' => html_pages.size,
        'pages_scraped' => 0,
        'message' => 'Found menu pages but could not extract usable text',
      })
      return
    end

    # Store HTML menu page URLs as MenuSource records
    scrape_result[:source_urls].each do |url|
      next if dr.menu_sources.exists?(source_url: url)

      dr.menu_sources.create!(
        source_url: url,
        source_type: :html,
        status: :active,
      )
    rescue StandardError => e
      Rails.logger.warn "WebMenuScrapeJob: failed to create HTML MenuSource: #{e.message}"
    end

    # Find or create a linked restaurant for the OcrMenuImport
    restaurant = dr.restaurant
    unless restaurant
      update_status!(dr, 'completed', details: {
        'html_pages_found' => html_pages.size,
        'pages_scraped' => scrape_result[:pages_scraped],
        'menu_text_length' => scrape_result[:menu_text].length,
        'message' => 'Menu text scraped successfully but no linked restaurant — approve the discovered restaurant first to create an import',
      })
      return
    end

    # Create OcrMenuImport and process through GPT
    import = OcrMenuImport.create!(
      restaurant: restaurant,
      name: "Web menu scrape – #{dr.name}",
      status: 'pending',
      metadata: {
        'source' => 'web_scrape',
        'discovered_restaurant_id' => dr.id,
        'source_urls' => scrape_result[:source_urls],
      },
    )

    begin
      import.process! # pending → processing
      processor = WebMenuProcessor.new(import)
      processor.process(
        menu_text: scrape_result[:menu_text],
        source_urls: scrape_result[:source_urls],
      )
      import.complete! # processing → completed

      update_status!(dr, 'completed', details: {
        'html_pages_found' => html_pages.size,
        'pages_scraped' => scrape_result[:pages_scraped],
        'pdf_urls_found' => pdf_urls.size,
        'ocr_menu_import_id' => import.id,
        'sections_count' => import.ocr_menu_sections.count,
        'items_count' => import.ocr_menu_items.count,
        'message' => 'Web menu successfully scraped and parsed',
      })
    rescue StandardError => e
      import.fail!(e.message) rescue nil
      update_status!(dr, 'failed', error: "Processing failed: #{e.message}")
      Rails.logger.error "WebMenuScrapeJob: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    end
  end

  private

  def update_status!(dr, status, error: nil, details: {})
    metadata = dr.metadata.is_a?(Hash) ? dr.metadata : {}
    scrape_data = (metadata['web_menu_scrape'].is_a?(Hash) ? metadata['web_menu_scrape'] : {})
    scrape_data = scrape_data.merge(
      'status' => status,
      'updated_at' => Time.current.iso8601,
    )
    scrape_data['error'] = error if error.present?
    scrape_data = scrape_data.merge(details) if details.present?

    metadata['web_menu_scrape'] = scrape_data
    dr.update!(metadata: metadata)
  end

  def update_metadata!(dr, hash)
    metadata = dr.metadata.is_a?(Hash) ? dr.metadata : {}
    metadata = metadata.merge(hash)
    dr.update!(metadata: metadata)
  end
end
