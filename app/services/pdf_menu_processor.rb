begin
  require 'google/cloud/vision'
rescue LoadError
  Rails.logger.debug { '[PdfMenuProcessor] google-cloud-vision not available; vision OCR disabled' } if defined?(Rails)
end
require 'mini_magick'
require 'json'
require 'pdf/reader'
require 'ostruct'
begin
  require 'openai'
rescue LoadError
  Rails.logger.debug { '[PdfMenuProcessor] openai gem not available; GPT features disabled' } if defined?(Rails)
end

class PdfMenuProcessor
  class ProcessingError < StandardError; end

  def initialize(ocr_menu_import, openai_client: nil, vision_client: nil)
    @ocr_menu_import = ocr_menu_import
    @restaurant = ocr_menu_import.restaurant
    @openai_client = openai_client
    @vision_client = vision_client
  end

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

  def process
    return unless @ocr_menu_import.pdf_file.attached?

    begin
      @ocr_menu_import.update!(metadata: (@ocr_menu_import.metadata || {}).merge('phase' => 'extracting_pages'))
      # Extract text from PDF (handles text-based and image-based PDFs)
      pdf_text = extract_text_from_pdf

      begin
        if @ocr_menu_import.respond_to?(:source_locale) && @ocr_menu_import.source_locale.to_s.strip == ''
          detected = detect_source_locale(pdf_text)
          if detected.present?
            @ocr_menu_import.update!(source_locale: detected)
            ensure_restaurant_locale!(detected)
          end
        end
      rescue StandardError => e
        Rails.logger.warn "PdfMenuProcessor: source locale detection failed: #{e.class}: #{e.message}"
      end

      # Parse menu structure using ChatGPT (text-based first, then vision fallback)
      @ocr_menu_import.update!(metadata: (@ocr_menu_import.metadata || {}).merge('phase' => 'parsing_menu'))
      menu_data = parse_menu_with_chatgpt(pdf_text)

      # If text-based parsing found no sections, try vision-based parsing
      # (handles multi-column layouts, decorative PDFs, etc.)
      if Array(menu_data[:sections]).empty? && @ocr_menu_import.pdf_file.attached?
        Rails.logger.info 'PdfMenuProcessor: text-based parsing found 0 sections; retrying with vision-based parsing'
        @ocr_menu_import.update!(metadata: (@ocr_menu_import.metadata || {}).merge('phase' => 'parsing_menu_vision'))
        vision_data = parse_menu_with_vision
        menu_data = vision_data if Array(vision_data[:sections]).any?
      end

      # Save parsed data to the database
      @ocr_menu_import.update!(metadata: (@ocr_menu_import.metadata || {}).merge('phase' => 'saving_menu'))
      save_menu_structure(menu_data, source_text: pdf_text)

      @ocr_menu_import.update!(metadata: (@ocr_menu_import.metadata || {}).merge('phase' => 'completed'))

      true
    rescue StandardError => e
      Rails.logger.error "Error in PdfMenuProcessor: #{e.message}\n#{e.backtrace.join("\n")}"
      raise ProcessingError, "Failed to process PDF: #{e.message}"
    end
  end

  private

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

  # Extract text from PDF with dual strategy:
  # 1) If the PDF contains selectable text, extract directly.
  # 2) Otherwise, render each page to an image and OCR it with Google Cloud Vision.
  def extract_text_from_pdf
    return '' unless @ocr_menu_import.pdf_file.attached?

    text_pages = []
    pdf_path = nil
    tempfile = Tempfile.new(['pdf', '.pdf'])

    begin
      # Download the PDF to a temp file
      File.binwrite(tempfile.path, @ocr_menu_import.pdf_file.download)
      pdf_path = tempfile.path

      # First attempt: use PDF::Reader to see if the PDF has extractable text
      reader = PDF::Reader.new(pdf_path)
      total_pages = reader.page_count
      @ocr_menu_import.update!(total_pages: total_pages, processed_pages: 0)
      @ocr_menu_import.update!(metadata: (@ocr_menu_import.metadata || {}).merge('phase' => 'extracting_pages', 'pages_total' => total_pages, 'pages_processed' => 0))

      extracted_text = []
      empty_text_pages = 0
      reader.pages.each_with_index do |page, _idx|
        page_text = (page.text || '').to_s.strip
        if page_text.blank? || page_text.gsub(/\s+/, '').length < 10
          empty_text_pages += 1
        end
        extracted_text << page_text
      end

      if empty_text_pages < (total_pages * 0.6).ceil
        # Treat as text-based PDF
        extracted_text.each_with_index do |t, idx|
          text_pages << t
          @ocr_menu_import.update!(processed_pages: idx + 1)
          @ocr_menu_import.update!(metadata: (@ocr_menu_import.metadata || {}).merge('phase' => 'extracting_pages', 'pages_total' => total_pages, 'pages_processed' => (idx + 1)))
        end
      else
        # Treat as image-based PDF: render pages to images and OCR them
        text_pages = ocr_pdf_images(pdf_path, total_pages)
      end

      # Combine text from all pages, separated by form feed to preserve page boundaries
      combined_text = text_pages.map(&:to_s).join("\n\f\n")
      combined_text
    ensure
      tempfile.close
      tempfile.unlink
    end
  end

  # Render PDF pages to images and OCR each page.
  def ocr_pdf_images(pdf_path, total_pages)
    text_pages = []
    Dir.mktmpdir(['pdf_pages']) do |dir|
      # Render each page to a PNG at good resolution for OCR
      # Using ImageMagick via MiniMagick. Requires ImageMagick installed.
      # Output filenames will be like page-0.png, page-1.png, ...
      begin
        MiniMagick.convert do |convert|
          convert.density(300)
          convert << pdf_path
          convert.quality(90)
          convert << File.join(dir, 'page-%d.png')
        end
      rescue StandardError => e
        Rails.logger.error "Error rendering PDF to images: #{e.message}"
        raise ProcessingError, "Failed to render PDF pages for OCR: #{e.message}"
      end

      # OCR each generated image file using Google Cloud Vision (injectable for tests)
      image_annotator = @vision_client
      if image_annotator.nil?
        raise ProcessingError, 'Google Cloud Vision is not available' unless defined?(Google::Cloud::Vision)

        image_annotator = Google::Cloud::Vision.image_annotator
      end
      processed = 0
      Dir[File.join(dir, 'page-*.png')].sort_by do |p|
        p[/page-(\d+)\.png/, 1].to_i
      end.each do |image_path|
        response = image_annotator.text_detection image: image_path
        annotation = response.responses.first
        page_text = annotation&.text_annotations&.first&.description.to_s
        text_pages << page_text
      rescue StandardError => e
        Rails.logger.error "Error OCR'ing image #{image_path}: #{e.message}"
        text_pages << ''
      ensure
        processed += 1
        @ocr_menu_import.update!(processed_pages: [processed, total_pages].min)
        @ocr_menu_import.update!(metadata: (@ocr_menu_import.metadata || {}).merge('phase' => 'extracting_pages', 'pages_total' => total_pages, 'pages_processed' => [processed, total_pages].min))
      end
    end
    text_pages
  end

  # Ask OpenAI to parse the menu text into a structured JSON format.
  # Returns a Ruby Hash with keys like :sections => [ { name:, items: [ { name:, description:, price:, allergens: [] } ] } ]
  def parse_menu_with_chatgpt(text)
    # If no text was extracted from the PDF, return an empty structure to avoid unnecessary API calls
    if text.to_s.strip.blank?
      Rails.logger.info 'PdfMenuProcessor: No text extracted from PDF; returning empty menu structure'
      return { sections: [] }
    end

    venue_context = build_venue_context
    prompt = <<~PROMPT
      You are given the full text content of a #{venue_context[:label]} menu, potentially with page breaks.

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
                   "price": <numeric price or null>,
                   "size_prices": {"bottle": null, "glass": null, "large_glass": null, "half_bottle": null, "carafe": null},
                   "allergens": ["gluten", "dairy", ...]  // any allergens mentioned
                 }
               ]
             }
           ]
         }

      2. If something is unknown, use null or empty values.
      3. Output only valid JSON. Do not include any commentary.

      MENU TEXT:
      #{text}
    PROMPT

    # Strengthen the prompt to avoid fenced code blocks
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

    # Normalize content: strip code fences like ```json ... ``` or ``` ... ```
    normalized = content.to_s.strip
    if normalized.start_with?('```')
      normalized = normalized.sub(/^```\w*\s*/m, '')
      normalized = normalized.sub(/```\s*\z/m, '')
      normalized = normalized.strip
    end

    begin
      json = JSON.parse(normalized)
    rescue JSON::ParserError
      # Try to extract a JSON object by locating the first '{' and last '}'
      json_str = begin
        start_idx = normalized.index('{')
        end_idx = normalized.rindex('}')
        start_idx && end_idx && end_idx > start_idx ? normalized[start_idx..end_idx] : nil
      rescue StandardError
        nil
      end

      if json_str.blank?
        Rails.logger.warn 'PdfMenuProcessor: Could not locate valid JSON in ChatGPT response; returning empty structure'
        return { sections: [] }
      end

      begin
        json = JSON.parse(json_str)
      rescue JSON::ParserError => e
        Rails.logger.warn "PdfMenuProcessor: JSON parse failed even after cleanup: #{e.message}; returning empty structure"
        return { sections: [] }
      end
    end
    # Ensure symbolized keys downstream
    json.deep_symbolize_keys
  end

  # Vision-based parsing: render PDF pages to images and send to GPT-4o vision.
  # This handles multi-column layouts, decorative designs, and PDFs where text
  # extraction produces garbled output due to complex visual structure.
  def parse_menu_with_vision
    return { sections: [] } unless @ocr_menu_import.pdf_file.attached?

    api_key = Rails.application.credentials.openai_api_key
    if api_key.blank?
      Rails.logger.warn 'PdfMenuProcessor: openai_api_key missing; vision parsing skipped'
      return { sections: [] }
    end

    unless defined?(OpenAI)
      Rails.logger.warn 'PdfMenuProcessor: OpenAI gem not available; vision parsing skipped'
      return { sections: [] }
    end

    # Use gpt-4o for vision (better at complex layouts than gpt-4o-mini)
    vision_model = ENV.fetch('OPENAI_VISION_MODEL', 'gpt-4o')

    tempfile = Tempfile.new(['pdf', '.pdf'])
    begin
      File.binwrite(tempfile.path, @ocr_menu_import.pdf_file.download)

      # Render pages to images and base64-encode them
      image_contents = render_pdf_pages_to_base64(tempfile.path)
      if image_contents.empty?
        Rails.logger.warn 'PdfMenuProcessor: could not render PDF pages to images for vision parsing'
        return { sections: [] }
      end

      venue_context = build_venue_context

      # Build vision message with page images
      user_content = []
      user_content << {
        type: 'text',
        text: <<~PROMPT,
          You are looking at images of a #{venue_context[:label]} menu (#{image_contents.size} page(s)).

          #{venue_context[:instructions]}

          TASK:
          1. Visually examine each page image. Pay attention to column layouts, decorative text, and groupings.
          2. Parse ALL menu items into JSON with this exact schema:
             {
               "sections": [
                 {
                   "name": "<section name>",
                   "items": [
                     {
                       "name": "<item name>",
                       "description": "<item description or empty>",
                       "price": <numeric price or null>,
                       "size_prices": {"bottle": null, "glass": null, "large_glass": null, "half_bottle": null, "carafe": null},
                       "allergens": []
                     }
                   ]
                 }
               ]
             }

          3. If the menu has multiple columns, parse EACH column as its own section(s).
          4. If something is unknown, use null or empty values.
          5. Output ONLY valid JSON. No commentary, no markdown fences.
        PROMPT
      }

      image_contents.each_with_index do |b64, idx|
        user_content << {
          type: 'image_url',
          image_url: {
            url: "data:image/png;base64,#{b64}",
            detail: 'high',
          },
        }
      end

      # Make the vision API call with appropriate timeout
      timeout_seconds = [120 * image_contents.size, 360].min
      wall_clock_limit = timeout_seconds + 30
      client = @openai_client || OpenAI::Client.new(access_token: api_key, request_timeout: timeout_seconds)

      Rails.logger.info "PdfMenuProcessor: vision parsing #{image_contents.size} page(s) with #{vision_model} (timeout: #{timeout_seconds}s)"

      response = nil
      attempts = 0
      begin
        attempts += 1
        Timeout.timeout(wall_clock_limit, Net::ReadTimeout, "Vision call exceeded #{wall_clock_limit}s") do
          response = client.chat(parameters: {
            model: vision_model,
            temperature: 0,
            max_tokens: 16_000,
            response_format: { type: 'json_object' },
            messages: [
              { role: 'system', content: 'You are a helpful assistant that outputs only valid JSON.' },
              { role: 'user', content: user_content },
            ],
          })
        end
      rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ETIMEDOUT, Faraday::TimeoutError => e
        if attempts < 2
          Rails.logger.info "PdfMenuProcessor: vision attempt #{attempts} timed out; retrying..."
          sleep(2)
          retry
        else
          Rails.logger.warn "PdfMenuProcessor: vision parsing failed after #{attempts} attempts: #{e.class} - #{e.message}"
          return { sections: [] }
        end
      end

      content = response&.dig('choices', 0, 'message', 'content').to_s.strip
      if content.blank?
        Rails.logger.warn 'PdfMenuProcessor: vision API returned empty response'
        return { sections: [] }
      end

      # Parse JSON response
      normalized = content.sub(/\A```\w*\s*/m, '').sub(/```\s*\z/m, '').strip
      json = begin
        JSON.parse(normalized)
      rescue JSON::ParserError
        start_idx = normalized.index('{')
        end_idx = normalized.rindex('}')
        if start_idx && end_idx && end_idx > start_idx
          JSON.parse(normalized[start_idx..end_idx]) rescue nil
        end
      end

      if json.nil?
        Rails.logger.warn 'PdfMenuProcessor: vision response was not valid JSON'
        return { sections: [] }
      end

      result = json.deep_symbolize_keys
      section_count = Array(result[:sections]).size
      item_count = Array(result[:sections]).sum { |s| Array(s[:items]).size }
      Rails.logger.info "PdfMenuProcessor: vision parsing found #{section_count} sections, #{item_count} items"
      result
    rescue StandardError => e
      Rails.logger.error "PdfMenuProcessor: vision parsing error: #{e.class}: #{e.message}"
      { sections: [] }
    ensure
      tempfile.close
      tempfile.unlink
    end
  end

  # Render PDF pages to PNG images and return base64-encoded strings
  def render_pdf_pages_to_base64(pdf_path)
    images = []
    Dir.mktmpdir(['pdf_vision']) do |dir|
      MiniMagick.convert do |convert|
        convert.density(150)
        convert << pdf_path
        convert.quality(80)
        convert.resize('1200x1600>')
        convert << File.join(dir, 'page-%d.png')
      end

      Dir[File.join(dir, 'page-*.png')].sort_by { |p| p[/page-(\d+)\.png/, 1].to_i }.each do |img_path|
        images << Base64.strict_encode64(File.binread(img_path))
      end
    end
    images
  rescue StandardError => e
    Rails.logger.error "PdfMenuProcessor: failed to render PDF pages: #{e.class}: #{e.message}"
    []
  end

  def ask_chatgpt(prompt)
    api_key = Rails.application.credentials.openai_api_key

    # Fallback when OpenAI key is not configured
    if api_key.blank?
      Rails.logger.warn 'PdfMenuProcessor: openai_api_key missing; using fallback empty menu structure'
      return OpenStruct.new(parsed_response: {
        'choices' => [
          { 'message' => { 'content' => { sections: [] }.to_json } },
        ],
      })
    end

    unless defined?(OpenAI)
      Rails.logger.warn 'PdfMenuProcessor: OpenAI gem not available; using fallback empty menu structure'
      return OpenStruct.new(parsed_response: {
        'choices' => [
          { 'message' => { 'content' => { sections: [] }.to_json } },
        ],
      })
    end

    model = Rails.application.credentials.dig(:openai, :model) ||
            Rails.application.credentials.openai_model ||
            ENV['OPENAI_MODEL'] ||
            'gpt-3.5-turbo'
    # Network robustness: timeouts and limited retries (OpenAI SDK)
    # Scale timeout for large prompts — GPT needs more time to generate structured JSON for big menus
    base_timeout = (ENV['OPENAI_TIMEOUT'] || 120).to_i
    prompt_chars = prompt.to_s.length
    timeout_seconds = if prompt_chars > 10_000
                        [base_timeout * 3, 360].min  # up to 6 min for large menus
                      elsif prompt_chars > 5_000
                        [base_timeout * 2, 300].min  # up to 5 min for medium menus
                      else
                        base_timeout
                      end
    # Hard wall-clock limit per attempt (request_timeout only covers individual reads,
    # not slow-trickle responses that keep the connection alive)
    wall_clock_limit = timeout_seconds + 30
    attempts = 0
    # Always build a client with the scaled timeout (the global client may have a shorter default)
    client = @openai_client || OpenAI::Client.new(access_token: api_key,
                                                  request_timeout: timeout_seconds,)
    begin
      attempts += 1
      # Some models support response_format json_object; skip if it raises an error
      parameters = {
        model: model,
        temperature: 0,
        messages: [
          { role: 'system', content: 'You are a helpful assistant that outputs only valid JSON.' },
          { role: 'user', content: prompt },
        ],
      }
      # Hard wall-clock timeout wraps each attempt
      Timeout.timeout(wall_clock_limit, Net::ReadTimeout, "OpenAI call exceeded #{wall_clock_limit}s wall-clock limit") do
        # Try with response_format first; fall back without it if the model rejects it
        # Only rescue format-related errors — let timeout/network errors bubble up to the outer retry loop
        begin
          parameters[:response_format] = { type: 'json_object' }
          response = client.chat(parameters: parameters)
        rescue Faraday::BadRequestError, ArgumentError => e
          Rails.logger.info "PdfMenuProcessor: response_format not supported (#{e.class}); retrying without it"
          parameters.delete(:response_format)
          response = client.chat(parameters: parameters)
        end
      end
    rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ETIMEDOUT, SocketError, Faraday::TimeoutError => e
      if attempts < 3
        Rails.logger.info "PdfMenuProcessor: OpenAI attempt #{attempts} failed (#{e.class}); retrying in #{1.5 * attempts}s..."
        sleep(1.5 * attempts)
        retry
      else
        Rails.logger.warn "PdfMenuProcessor: OpenAI request failed after #{attempts} retries: #{e.class} - #{e.message}; using fallback empty menu structure"
        return OpenStruct.new(parsed_response: {
          'choices' => [
            { 'message' => { 'content' => { sections: [] }.to_json } },
          ],
        })
      end
    end

    # If API returns an error or empty content, fallback to minimal structure to avoid crashes
    content = begin
      response.dig('choices', 0, 'message', 'content')
    rescue StandardError
      nil
    end

    if content.blank?
      Rails.logger.warn 'PdfMenuProcessor: OpenAI returned empty/invalid response; using fallback empty menu structure'
      return OpenStruct.new(parsed_response: {
        'choices' => [
          { 'message' => { 'content' => { sections: [] }.to_json } },
        ],
      })
    end

    response
  end

  def save_menu_structure(menu_data, source_text: nil)
    sections = Array(menu_data[:sections])
    sections_total = sections.size
    items_total = sections.sum { |s| Array(s[:items]).size }
    @ocr_menu_import.update!(metadata: (@ocr_menu_import.metadata || {}).merge('phase' => 'saving_menu', 'sections_total' => sections_total, 'sections_processed' => 0, 'items_total' => items_total, 'items_processed' => 0))

    normalized_source_text = normalize_allergen_source_text(source_text)

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
          item_metadata = {}
          # Store wine size prices in metadata if present
          if item_data[:size_prices].is_a?(Hash)
            sp = item_data[:size_prices].select { |_k, v| v.present? && v.to_f > 0 }
            item_metadata['size_prices'] = sp.transform_values(&:to_f) if sp.any?
          end

          section.ocr_menu_items.create!(
            name: item_data[:name],
            description: item_data[:description],
            price: item_data[:price],
            allergens: filter_allergens_from_source(item_data[:allergens] || [], normalized_source_text),
            is_vegetarian: item_data[:is_vegetarian] || false,
            is_vegan: item_data[:is_vegan] || false,
            is_gluten_free: item_data[:is_gluten_free] || false,
            is_dairy_free: item_data[:is_dairy_free] || false,
            sequence: item_index + 1,
            is_confirmed: true,
            metadata: item_metadata.presence || {},
          )

          items_processed += 1
          if (items_processed % 5).zero? || items_processed == items_total
            @ocr_menu_import.update!(metadata: (@ocr_menu_import.metadata || {}).merge('phase' => 'saving_menu', 'sections_total' => sections_total, 'sections_processed' => section_index, 'items_total' => items_total, 'items_processed' => items_processed))
          end
        end

        @ocr_menu_import.update!(metadata: (@ocr_menu_import.metadata || {}).merge('phase' => 'saving_menu', 'sections_total' => sections_total, 'sections_processed' => (section_index + 1), 'items_total' => items_total, 'items_processed' => items_processed))
      end
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
        - Do NOT create separate items for different sizes of the same wine.
        - If multiple serving sizes are listed (bottle, glass, carafe, half bottle, large glass),
          include ALL prices in a "size_prices" object on the item.
        - "price" should be the bottle price (or the first/primary price listed).
        - Only include size keys that have prices on the menu. Omit sizes not listed.
        - Valid size keys: "bottle", "glass", "large_glass", "half_bottle", "carafe".
        - Use sections like "Red Wines", "White Wines", "Sparkling", "Rosé", "Dessert Wines" if the menu groups them this way.
      WINE
    end

    if is_whiskey_bar
      labels << 'whiskey/spirits bar'
      instructions_parts << <<~WHISKEY.strip
        SPIRITS/WHISKEY MENU GUIDANCE:
        - Group spirits by type or origin (e.g. "Scotch", "Irish Whiskey", "Bourbon", "Japanese Whisky").
        - Include distillery/brand name as the item name.
        - Include age statement, ABV, region/distillery, and tasting notes in the description where available.
        - If multiple pour sizes are listed (e.g. 25ml, 50ml), create separate items or note both in description.
      WHISKEY
    end

    if is_bar && !is_wine_bar && !is_whiskey_bar
      labels << 'bar'
      instructions_parts << <<~BAR.strip
        BAR/COCKTAIL MENU GUIDANCE:
        - Group cocktails by style (e.g. "Signature Cocktails", "Classic Cocktails", "Mocktails").
        - Include the base spirit and key ingredients in the description.
        - For beer/draught lists, include brewery, style, and ABV in the description.
        - If both draught and bottle prices exist, note this in the description or create separate items.
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

    instructions = if instructions_parts.any?
                     instructions_parts.join("\n\n")
                   else
                     'Parse the menu items into structured sections with items, descriptions, and prices.'
                   end

    { label: label, instructions: instructions }
  end

  def normalize_allergen_source_text(text)
    s = text.to_s.downcase
    s = s.gsub(/[^a-z0-9\s]/, ' ')
    s.gsub(/\s+/, ' ').strip
  end

  def filter_allergens_from_source(allergens, normalized_source_text)
    return [] if normalized_source_text.blank?

    Array(allergens).map { |a| a.to_s.downcase.strip }.compact_blank.uniq.select do |a|
      token = a.gsub(/[^a-z0-9\s]/, ' ').gsub(/\s+/, ' ').strip
      next false if token.blank?

      normalized_source_text.match?(/\b#{Regexp.escape(token)}\b/)
    end
  end
end
