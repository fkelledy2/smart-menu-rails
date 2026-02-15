require 'json'
require 'ostruct'
begin
  require 'openai'
rescue LoadError
  Rails.logger.debug { '[WebMenuProcessor] openai gem not available; GPT features disabled' } if defined?(Rails)
end

# Processes scraped HTML menu text through GPT and saves to OcrMenuImport.
# Reuses the same GPT structuring approach as PdfMenuProcessor but skips
# PDF/OCR entirely — works directly with clean text extracted from web pages.
class WebMenuProcessor
  class ProcessingError < StandardError; end

  def initialize(ocr_menu_import, openai_client: nil)
    @ocr_menu_import = ocr_menu_import
    @restaurant = ocr_menu_import.restaurant
    @openai_client = openai_client
  end

  # menu_text: String — clean text scraped from HTML menu pages
  # source_urls: [String] — the URLs the text was scraped from
  def process(menu_text:, source_urls: [])
    return false if menu_text.to_s.strip.blank?

    begin
      @ocr_menu_import.update!(
        total_pages: 1,
        processed_pages: 0,
        metadata: (@ocr_menu_import.metadata || {}).merge(
          'phase' => 'parsing_menu',
          'source' => 'web_scrape',
          'source_urls' => source_urls,
        ),
      )

      # Detect locale
      begin
        if @ocr_menu_import.respond_to?(:source_locale) && @ocr_menu_import.source_locale.to_s.strip == ''
          detected = detect_source_locale(menu_text)
          if detected.present?
            @ocr_menu_import.update!(source_locale: detected)
            ensure_restaurant_locale!(detected)
          end
        end
      rescue StandardError => e
        Rails.logger.warn "WebMenuProcessor: source locale detection failed: #{e.class}: #{e.message}"
      end

      # Parse with GPT
      menu_data = parse_menu_with_chatgpt(menu_text)

      # Save structured data
      @ocr_menu_import.update!(
        processed_pages: 1,
        metadata: (@ocr_menu_import.metadata || {}).merge('phase' => 'saving_menu'),
      )
      save_menu_structure(menu_data, source_text: menu_text)

      # Price inference pass: estimate prices for unpriced items
      @ocr_menu_import.update!(
        metadata: (@ocr_menu_import.metadata || {}).merge('phase' => 'estimating_prices'),
      )
      infer_missing_prices(menu_data)

      @ocr_menu_import.update!(
        metadata: (@ocr_menu_import.metadata || {}).merge('phase' => 'completed'),
      )

      true
    rescue StandardError => e
      Rails.logger.error "Error in WebMenuProcessor: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      raise ProcessingError, "Failed to process web menu: #{e.message}"
    end
  end

  private

  def detect_source_locale(text)
    sample = text.to_s.strip
    return nil if sample.blank?

    sample = sample[0, 4000]

    prompt = <<~PROMPT
      Detect the primary language of the following restaurant menu text.
      Reply ONLY with a two-letter ISO 639-1 language code from this set: en, fr, it, es.

      MENU TEXT:
      #{sample}
    PROMPT

    response = ask_chatgpt(prompt)
    content = begin
      if response.is_a?(Hash)
        response.dig('choices', 0, 'message', 'content')
      else
        response.parsed_response.dig('choices', 0, 'message', 'content')
      end
    rescue StandardError
      nil
    end

    code = content.to_s.strip.downcase
    code[/\b(en|fr|it|es)\b/, 1]
  end

  def ensure_restaurant_locale!(locale)
    code = locale.to_s.strip
    return if code.blank?

    code = code.split(/[-_]/).first.to_s.upcase
    return if code.blank?

    existing = Restaurantlocale.where(restaurant_id: @restaurant.id)
      .where('LOWER(locale) = ?', code.downcase)
      .first

    if existing
      existing.update!(status: 'active') if existing.status != 'active'
      return
    end

    Restaurantlocale.create!(
      restaurant_id: @restaurant.id,
      locale: code,
      status: 'active',
      dfault: false,
    )
  rescue StandardError
    nil
  end

  def parse_menu_with_chatgpt(text)
    if text.to_s.strip.blank?
      Rails.logger.info 'WebMenuProcessor: No text provided; returning empty menu structure'
      return { sections: [] }
    end

    venue_context = build_venue_context

    prompt = <<~PROMPT
      You are given text scraped from a #{venue_context[:label]} website's menu page(s).
      The text may contain HTML artifacts, navigation elements, or repeated content — ignore those.
      Extract ALL menu items, sections, and prices from the text.

      IMPORTANT: Include ALL items even if they do not have a price listed.
      Many bars and restaurants list spirits, wines, or other items by name and description
      without showing a price — these are still valid menu items. Use null for the price field
      when no price is shown.

      #{venue_context[:instructions]}

      TASK:
      1. Parse the menu into JSON with this exact schema:
         {
           "sections": [
             {
               "name": "<section name>",
               "items": [
                 {
                   "name": "<item name>",
                   "description": "<item description or empty>",
                   "price": <numeric price or null if not listed>,
                   "allergens": ["gluten", "dairy", ...]
                 }
               ]
             }
           ]
         }

      2. If something is unknown, use null or empty values.
      3. Output only valid JSON. Do not include any commentary.
      4. Merge duplicate sections if the same section appears on multiple pages.
      5. Do NOT skip items just because they lack a price — include them with price: null.

      MENU TEXT:
      #{text[0, 50_000]}
    PROMPT

    prompt = "#{prompt}\n\nStrict rules: Output ONLY raw JSON. Do NOT wrap in markdown fences."

    response = ask_chatgpt(prompt)
    content = begin
      if response.is_a?(Hash)
        response.dig('choices', 0, 'message', 'content')
      else
        response.parsed_response.dig('choices', 0, 'message', 'content')
      end
    rescue StandardError
      nil
    end
    raise ProcessingError, 'No response from ChatGPT' if content.blank?

    normalized = content.to_s.strip
    if normalized.start_with?('```')
      normalized = normalized.sub(/^```\w*\s*/m, '')
      normalized = normalized.sub(/```\s*\z/m, '')
      normalized = normalized.strip
    end

    begin
      json = JSON.parse(normalized)
    rescue JSON::ParserError
      json_str = begin
        start_idx = normalized.index('{')
        end_idx = normalized.rindex('}')
        start_idx && end_idx && end_idx > start_idx ? normalized[start_idx..end_idx] : nil
      rescue StandardError
        nil
      end

      if json_str.blank?
        Rails.logger.warn 'WebMenuProcessor: Could not locate valid JSON in ChatGPT response'
        return { sections: [] }
      end

      begin
        json = JSON.parse(json_str)
      rescue JSON::ParserError => e
        Rails.logger.warn "WebMenuProcessor: JSON parse failed: #{e.message}"
        return { sections: [] }
      end
    end

    json.deep_symbolize_keys
  end

  def ask_chatgpt(prompt)
    api_key = Rails.application.credentials.openai_api_key

    if api_key.blank?
      Rails.logger.warn 'WebMenuProcessor: openai_api_key missing; using fallback'
      return fallback_response
    end

    unless defined?(OpenAI)
      Rails.logger.warn 'WebMenuProcessor: OpenAI gem not available; using fallback'
      return fallback_response
    end

    model = Rails.application.credentials.dig(:openai, :model) ||
            Rails.application.credentials.openai_model ||
            ENV['OPENAI_MODEL'] ||
            'gpt-3.5-turbo'

    timeout_seconds = (ENV['OPENAI_TIMEOUT'] || 120).to_i
    attempts = 0
    client = @openai_client || Rails.configuration.x.openai_client || OpenAI::Client.new(
      access_token: api_key,
      request_timeout: timeout_seconds,
    )

    begin
      attempts += 1
      parameters = {
        model: model,
        temperature: 0,
        messages: [
          { role: 'system', content: 'You are a helpful assistant that outputs only valid JSON.' },
          { role: 'user', content: prompt },
        ],
      }
      begin
        parameters[:response_format] = { type: 'json_object' }
        response = client.chat(parameters: parameters)
      rescue StandardError
        parameters.delete(:response_format)
        response = client.chat(parameters: parameters)
      end
    rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ETIMEDOUT, SocketError, Faraday::TimeoutError => e
      if attempts < 3
        sleep(1.5 * attempts)
        retry
      else
        Rails.logger.warn "WebMenuProcessor: OpenAI request failed after retries: #{e.class} - #{e.message}"
        return fallback_response
      end
    end

    content = begin
      response.dig('choices', 0, 'message', 'content')
    rescue StandardError
      nil
    end

    if content.blank?
      Rails.logger.warn 'WebMenuProcessor: OpenAI returned empty response'
      return fallback_response
    end

    response
  end

  def fallback_response
    OpenStruct.new(parsed_response: {
      'choices' => [
        { 'message' => { 'content' => { sections: [] }.to_json } },
      ],
    })
  end

  def save_menu_structure(menu_data, source_text: nil)
    sections = Array(menu_data[:sections])
    sections_total = sections.size
    items_total = sections.sum { |s| Array(s[:items]).size }
    @ocr_menu_import.update!(metadata: (@ocr_menu_import.metadata || {}).merge(
      'phase' => 'saving_menu',
      'sections_total' => sections_total,
      'items_total' => items_total,
    ))

    normalized_source_text = normalize_source_text(source_text)

    OcrMenuImport.transaction do
      items_processed = 0
      sections.each_with_index do |section_data, section_index|
        section = @ocr_menu_import.ocr_menu_sections.create!(
          name: section_data[:name],
          description: section_data[:description],
          sequence: section_index + 1,
          is_confirmed: true,
        )

        Array(section_data[:items]).each_with_index do |item_data, item_index|
          section.ocr_menu_items.create!(
            name: item_data[:name],
            description: item_data[:description],
            price: item_data[:price],
            allergens: filter_allergens(item_data[:allergens] || [], normalized_source_text),
            is_vegetarian: item_data[:is_vegetarian] || false,
            is_vegan: item_data[:is_vegan] || false,
            is_gluten_free: item_data[:is_gluten_free] || false,
            is_dairy_free: item_data[:is_dairy_free] || false,
            sequence: item_index + 1,
            is_confirmed: true,
          )
          items_processed += 1
        end
      end
    end
  end

  # Second GPT pass: estimate prices for items that have no price.
  # Uses priced items as reference points and venue/location context.
  def infer_missing_prices(menu_data)
    sections = @ocr_menu_import.ocr_menu_sections.includes(:ocr_menu_items).ordered
    unpriced_sections = []
    priced_reference = []

    sections.each do |section|
      items = section.ocr_menu_items.ordered
      unpriced = items.select { |i| i.price.blank? || i.price.to_f.zero? }
      priced = items.select { |i| i.price.present? && i.price.to_f > 0 }

      priced.each { |i| priced_reference << { section: section.name, name: i.name, price: i.price.to_f } }

      if unpriced.any?
        unpriced_sections << {
          section: section,
          items: unpriced,
        }
      end
    end

    return if unpriced_sections.empty?

    # Build the inference prompt
    venue_context = build_venue_context
    currency = @restaurant.try(:currency).presence || 'EUR'
    city = @restaurant.try(:city).presence || @restaurant.try(:discovered_restaurant)&.city_name || 'unknown city'
    country = @restaurant.try(:country_code).presence || @restaurant.try(:discovered_restaurant)&.country_code || ''

    reference_text = if priced_reference.any?
                       lines = priced_reference.first(15).map { |r| "  #{r[:section]} > #{r[:name]}: #{r[:price]}" }
                       "PRICED ITEMS FOR REFERENCE:\n#{lines.join("\n")}"
                     else
                       'No priced items available for reference.'
                     end

    unpriced_list = unpriced_sections.flat_map do |us|
      us[:items].map { |i| { section: us[:section].name, name: i.name, id: i.id } }
    end

    items_text = unpriced_list.map { |u| "  #{u[:section]} > #{u[:name]} (id:#{u[:id]})" }.join("\n")

    prompt = <<~PROMPT
      You are a pricing expert for #{venue_context[:label]} venues.
      A menu has been scraped from a #{venue_context[:label]} in #{city}#{country.present? ? ", #{country}" : ''}.
      Some items have prices and some do not. Your job is to estimate realistic per-serve
      prices (in #{currency}) for the unpriced items based on:
      - The priced items on the same menu as reference
      - Typical pricing for this type of venue and location
      - The category/section the item belongs to

      #{reference_text}

      UNPRICED ITEMS TO ESTIMATE:
      #{items_text}

      TASK:
      Return a JSON object mapping each item id to its estimated price (numeric).
      Example: { "123": 8.0, "456": 12.5 }

      Rules:
      - Output ONLY valid JSON. No commentary.
      - Use realistic prices for #{city}. Do not over or under estimate.
      - For spirits/whiskey/gin by the glass, typical Dublin bar prices are €7-€14.
      - For premium or rare spirits, price higher (€12-€20+).
      - If you truly cannot estimate, use the median price of the priced items.
    PROMPT

    prompt = "#{prompt}\n\nStrict rules: Output ONLY raw JSON. Do NOT wrap in markdown fences."

    begin
      response = ask_chatgpt(prompt)
      content = begin
        if response.is_a?(Hash)
          response.dig('choices', 0, 'message', 'content')
        else
          response.parsed_response.dig('choices', 0, 'message', 'content')
        end
      rescue StandardError
        nil
      end

      return if content.blank?

      normalized = content.to_s.strip
      normalized = normalized.sub(/^```\w*\s*/m, '').sub(/```\s*\z/m, '').strip if normalized.start_with?('```')

      estimates = begin
        JSON.parse(normalized)
      rescue JSON::ParserError
        json_str = normalized[normalized.index('{')..normalized.rindex('}')]
        JSON.parse(json_str) rescue {}
      end

      return if estimates.empty?

      estimated_count = 0
      estimates.each do |item_id_str, estimated_price|
        price = estimated_price.to_f
        next if price <= 0

        item = OcrMenuItem.find_by(id: item_id_str.to_i)
        next unless item
        next if item.price.present? && item.price.to_f > 0

        item.update!(
          price: price,
          metadata: (item.metadata || {}).merge('price_estimated' => true, 'price_source' => 'gpt_inference'),
        )
        estimated_count += 1
      end

      @ocr_menu_import.update!(
        metadata: (@ocr_menu_import.metadata || {}).merge('prices_estimated' => estimated_count),
      )

      Rails.logger.info "WebMenuProcessor: Estimated prices for #{estimated_count} items"
    rescue StandardError => e
      Rails.logger.warn "WebMenuProcessor: Price inference failed (non-fatal): #{e.message}"
    end
  end

  def build_venue_context
    types = Array(@restaurant.try(:establishment_types)).map(&:to_s).compact_blank

    is_wine_bar = types.include?('wine_bar')
    is_whiskey_bar = types.include?('whiskey_bar')
    is_bar = types.include?('bar')
    is_restaurant = types.include?('restaurant') || types.empty?

    labels = []
    instructions_parts = []

    if is_wine_bar
      labels << 'wine bar'
      instructions_parts << <<~WINE.strip
        WINE LIST GUIDANCE:
        - Group wines by region, grape variety, or style as shown in the source.
        - For each wine, include the full wine name (producer + cuvée if available).
        - Include vintage year, grape/blend, and region/appellation in the description.
        - If both glass and bottle prices are listed, create separate items.
        - Use sections like "Red Wines", "White Wines", "Sparkling", "Rosé" if the menu groups them.
      WINE
    end

    if is_whiskey_bar
      labels << 'whiskey/spirits bar'
      instructions_parts << <<~WHISKEY.strip
        SPIRITS/WHISKEY MENU GUIDANCE:
        - Group spirits by type or origin (e.g. "Scotch", "Irish Whiskey", "Bourbon").
        - Include distillery/brand name as the item name.
        - Include age statement, ABV, region, and tasting notes in the description where available.
      WHISKEY
    end

    if is_bar && !is_wine_bar && !is_whiskey_bar
      labels << 'bar'
      instructions_parts << <<~BAR.strip
        BAR/COCKTAIL MENU GUIDANCE:
        - Group cocktails by style (e.g. "Signature Cocktails", "Classic Cocktails", "Mocktails").
        - Include the base spirit and key ingredients in the description.
        - For beer/draught lists, include brewery, style, and ABV in the description.
      BAR
    end

    if is_restaurant
      labels << 'restaurant'
      instructions_parts << <<~REST.strip
        RESTAURANT MENU GUIDANCE:
        - Group items by course or category (e.g. "Starters", "Mains", "Desserts", "Sides").
        - Include a concise description of each dish.
        - Extract allergens where mentioned.
      REST
    end

    label = labels.uniq.join(' / ')
    label = 'restaurant' if label.blank?

    instructions = instructions_parts.any? ? instructions_parts.join("\n\n") : 'Parse the menu items into structured sections with items, descriptions, and prices.'

    { label: label, instructions: instructions }
  end

  def normalize_source_text(text)
    s = text.to_s.downcase
    s = s.gsub(/[^a-z0-9\s]/, ' ')
    s.gsub(/\s+/, ' ').strip
  end

  def filter_allergens(allergens, normalized_source_text)
    return [] if normalized_source_text.blank?

    Array(allergens).map { |a| a.to_s.downcase.strip }.compact_blank.uniq.select do |a|
      token = a.gsub(/[^a-z0-9\s]/, ' ').gsub(/\s+/, ' ').strip
      next false if token.blank?

      normalized_source_text.match?(/\b#{Regexp.escape(token)}\b/)
    end
  end
end
