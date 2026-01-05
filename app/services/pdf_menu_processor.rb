begin
  require 'google/cloud/vision'
rescue LoadError
end
require 'mini_magick'
require 'json'
require 'pdf/reader'
require 'ostruct'
begin
  require 'openai'
rescue LoadError
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
    code = code[/\b(en|fr|it|es)\b/, 1]
    code
  end

  def process
    return unless @ocr_menu_import.pdf_file.attached?

    begin
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

      # Parse menu structure using ChatGPT
      menu_data = parse_menu_with_chatgpt(pdf_text)

      # Save parsed data to the database
      save_menu_structure(menu_data)

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
        MiniMagick::Tool::Convert.new do |convert|
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
    prompt = <<~PROMPT
      You are given the full text content of a restaurant menu, potentially with page breaks.\n\n
      TASK:\n
      1. Parse the menu into JSON with this exact schema:\n
         {\n
           "sections": [\n
             {\n
               "name": "<section name>",\n
               "items": [\n
                 {\n
                   "name": "<item name>",\n
                   "description": "<item description or empty>",\n
                   "price": <numeric price or null>,\n
                   "allergens": ["gluten", "dairy", ...]  // any allergens mentioned\n
                 }\n
               ]\n
             }\n
           ]\n
         }\n\n
      2. If something is unknown, use null or empty values.\n
      3. Output only valid JSON. Do not include any commentary.\n\n
      MENU TEXT:\n
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
    timeout_seconds = (ENV['OPENAI_TIMEOUT'] || 120).to_i
    attempts = 0
    client = @openai_client || Rails.configuration.x.openai_client || OpenAI::Client.new(access_token: api_key,
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
        Rails.logger.warn "PdfMenuProcessor: OpenAI request failed after retries due to network error: #{e.class} - #{e.message}; using fallback empty menu structure"
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

  def save_menu_structure(menu_data)
    OcrMenuImport.transaction do
      menu_data[:sections].each_with_index do |section_data, section_index|
        section = @ocr_menu_import.ocr_menu_sections.create!(
          name: section_data[:name],
          description: section_data[:description],
          sequence: section_index + 1,
          is_confirmed: false,
        )

        section_data[:items].each_with_index do |item_data, item_index|
          section.ocr_menu_items.create!(
            name: item_data[:name],
            description: item_data[:description],
            price: item_data[:price],
            allergens: item_data[:allergens] || [],
            is_vegetarian: item_data[:is_vegetarian] || false,
            is_vegan: item_data[:is_vegan] || false,
            is_gluten_free: item_data[:is_gluten_free] || false,
            is_dairy_free: item_data[:is_dairy_free] || false,
            sequence: item_index + 1,
            is_confirmed: false,
          )
        end
      end
    end
  end
end
