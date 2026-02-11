require 'sidekiq'
require 'json'

class OcrMenuImportPolisherJob
  include Sidekiq::Job

  sidekiq_options queue: 'default', retry: 3

  def perform(ocr_menu_import_id)
    import = OcrMenuImport.includes(ocr_menu_sections: [:ocr_menu_items]).find_by(id: ocr_menu_import_id)
    return unless import

    normalize_only = import.normalize_only?

    restaurant = import.restaurant
    target_locale = restaurant_default_locale(restaurant)
    target_language = locale_to_language(target_locale)

    items = import.ocr_menu_items
    total = items.count
    processed = 0

    set_progress('queued', 0, total, import.id)

    import.ocr_menu_sections.ordered.each do |section|
      section_name = section.name.to_s
      section_description = section.respond_to?(:description) ? section.description.to_s : nil

      section.ocr_menu_items.ordered.each do |item|
        item.name = normalize_title(item.name)
        item.description = normalize_sentence(item.description)

        if item.description.to_s.strip == ''
          item.description = item.name
        end

        # AI guardrail: only generate new descriptions in full_enrich mode
        if texts_equal?(item.name, item.description) && !normalize_only
          begin
            gen = generate_description_via_llm(
              item_name: item.name,
              section_name: section_name,
              section_description: section_description,
              language: target_language,
            )
            item.description = gen if gen.present?
          rescue StandardError => e
            Rails.logger.warn("[OcrMenuImportPolisherJob] LLM description failed for item ##{item.id}: #{e.class}: #{e.message}")
          end
        end

        item.description = normalize_sentence(item.description)

        # AI guardrail: only generate image prompts in full_enrich mode
        if !normalize_only && item.respond_to?(:image_prompt) && item.image_prompt.to_s.strip == ''
          begin
            img_prompt = generate_image_prompt_via_llm(
              item_name: item.name,
              item_description: item.description,
              section_name: section_name,
              section_description: section_description,
              language: target_language,
            )
            item.image_prompt = img_prompt if img_prompt.present?
          rescue StandardError => e
            Rails.logger.warn("[OcrMenuImportPolisherJob] LLM image_prompt failed for item ##{item.id}: #{e.class}: #{e.message}")
          end
        end

        item.save! if item.changed?

        processed += 1
        set_progress('running', processed, total, import.id, message: "Polished '#{item.name}' (#{processed}/#{total})")
      end
    end

    set_progress('completed', total, total, import.id)
  rescue StandardError => e
    Rails.logger.error("[OcrMenuImportPolisherJob] Error polishing import ##{ocr_menu_import_id}: #{e.class}: #{e.message}")
    set_progress('failed', processed || 0, total || 0, ocr_menu_import_id, message: e.message)
    raise
  end

  private

  def set_progress(status, current, total, import_id, message: nil)
    return if jid.to_s.strip == ''

    payload = {
      status: status,
      current: current,
      total: total,
      message: message || 'AI polishing in progress',
      import_id: import_id,
    }

    Sidekiq.redis do |r|
      r.setex("ocr_polish:#{jid}", 24 * 3600, payload.to_json)
    end
  rescue StandardError => e
    Rails.logger.warn("[OcrMenuImportPolisherJob] Failed to write progress for #{jid}: #{e.class}: #{e.message}")
  end

  def normalize_title(text)
    s = text.to_s.strip.gsub(/\s+/, ' ')
    return s if s == ''

    s.titleize
  end

  def normalize_sentence(text)
    s = text.to_s.strip.gsub(/\s+/, ' ')
    return s if s == ''

    s = s.downcase
    s[0] = s[0].upcase if s[0]
    s
  end

  def texts_equal?(a, b)
    a.to_s.strip.casecmp?(b.to_s.strip)
  end

  def generate_description_via_llm(item_name:, section_name:, section_description: nil, language: nil)
    client = Rails.configuration.x.openai_client
    return nil unless client

    language_str = language.to_s.strip
    language_hint = language_str.present? ? " Write in #{language_str}." : ''

    system_msg = "You are a culinary copywriter. Write a concise, customer-facing, single-sentence menu description (max 24 words). No emojis. No allergens. No pricing. Do not invent ingredients or claims not explicitly present in the provided name/context.#{language_hint}"
    context_bits = []
    context_bits << "Section: #{section_name}." if section_name.present?
    context_bits << "Section description: #{section_description}." if section_description.to_s.strip != ''
    context_bits << "Language: #{language_str}." if language_str.present?

    user_msg = <<~PROMPT.strip
      Create a description for this menu item name:
      Name: #{item_name}
      Context: #{context_bits.join(' ')}
    PROMPT

    params = {
      model: ENV['OPENAI_MODEL'].presence || 'gpt-3.5-turbo',
      temperature: 0.7,
      messages: [
        { role: 'system', content: system_msg },
        { role: 'user', content: user_msg },
      ],
    }

    resp = client.chat(parameters: params)
    content = resp.dig('choices', 0, 'message', 'content').to_s.strip
    return nil if content == ''

    content.gsub(/[\s\n]+/, ' ').strip
  rescue StandardError => e
    Rails.logger.warn("[OcrMenuImportPolisherJob] OpenAI chat error: #{e.message}")
    nil
  end

  def generate_image_prompt_via_llm(item_name:, item_description:, section_name:, section_description: nil, language: nil)
    client = Rails.configuration.x.openai_client
    return nil unless client

    language_str = language.to_s.strip
    language_hint = language_str.present? ? " Write in #{language_str}." : ''

    system_msg = "You write short internal prompts for photorealistic food image generation. Be specific about visible presentation (plating, texture, color) but conservative. Do not invent ingredients, garnishes, sauces, or claims not explicitly present in the provided text. Do not mention allergens. Do not mention camera, lens, lighting, text, logos, or people. Output a single sentence (max 30 words).#{language_hint}"
    context_bits = []
    context_bits << "Section: #{section_name}." if section_name.present?
    context_bits << "Section description: #{section_description}." if section_description.to_s.strip != ''
    context_bits << "Language: #{language_str}." if language_str.present?

    user_msg = <<~PROMPT.strip
      Create an internal image prompt for this menu item.
      Use ONLY details explicitly present in these fields; if unclear, stay generic.

      Item name: #{item_name}
      Customer description: #{item_description}
      Context: #{context_bits.join(' ')}
    PROMPT

    params = {
      model: ENV['OPENAI_MODEL'].presence || 'gpt-3.5-turbo',
      temperature: 0.5,
      messages: [
        { role: 'system', content: system_msg },
        { role: 'user', content: user_msg },
      ],
    }

    resp = client.chat(parameters: params)
    content = resp.dig('choices', 0, 'message', 'content').to_s.strip
    return nil if content == ''

    content.gsub(/[\s\n]+/, ' ').strip
  rescue StandardError => e
    Rails.logger.warn("[OcrMenuImportPolisherJob] OpenAI image_prompt error: #{e.message}")
    nil
  end

  def restaurant_default_locale(restaurant)
    rl = restaurant&.defaultLocale
    s = rl&.locale.to_s
    s = s.split(/[-_]/).first.to_s.downcase
    s.presence || 'en'
  rescue StandardError
    'en'
  end

  def locale_to_language(locale)
    code = locale.to_s.split(/[-_]/).first.to_s.upcase
    case code
    when 'IT'
      'Italian'
    when 'FR'
      'French'
    when 'ES'
      'Spanish'
    when 'PT'
      'Portuguese'
    else
      'English'
    end
  end
end
