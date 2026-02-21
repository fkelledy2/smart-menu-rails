class Menu::ExtractCandidatesJob
  include Sidekiq::Job

  sidekiq_options queue: 'default', retry: 3

  WHISKEY_HINTS = %w[
    whisky whiskey scotch bourbon rye islay speyside highland lowland campbeltown
    single malt blended cask sherry peat peated
  ].freeze

  VINTAGE_REGEX = /\b(19\d{2}|20\d{2})\b/
  AGE_REGEX = /\b(\d{1,2})\s*(?:yo|y\.o\.|years?\s*old)\b/i
  SIZE_ML_REGEX = /\b(\d{2,4})\s*ml\b/i

  def perform(pipeline_run_id, trigger = nil)
    run = BeveragePipelineRun.find_by(id: pipeline_run_id)
    return unless run

    menu = run.menu

    run.update!(current_step: 'extract_candidates')

    items = menu.menuitems.includes(menusection: :menu)
    processed = 0
    needs_review = 0
    unresolved = 0

    items.find_each do |mi|
      category, conf, parsed, parse_conf = classify_and_parse(mi)

      needs_review_flag = category.present? ? (conf.to_f < 0.7 || parse_conf.to_f < 0.7) : true
      mi.update_columns(
        sommelier_category: category,
        sommelier_classification_confidence: conf,
        sommelier_parsed_fields: (parsed.is_a?(Hash) ? parsed : {}),
        sommelier_parse_confidence: parse_conf,
        sommelier_needs_review: needs_review_flag,
        updated_at: Time.current,
      )

      processed += 1
      if needs_review_flag
        needs_review += 1
        unresolved += 1 if category.blank?
      end
    end

    run.update!(
      items_processed: processed,
      needs_review_count: needs_review,
      unresolved_count: unresolved,
    )

    Menu::ResolveEntitiesJob.perform_async(run.id, trigger)
  rescue StandardError => e
    run&.update!(status: 'failed', error_summary: "#{e.class}: #{e.message}")
    Rails.logger.error("[ExtractCandidatesJob] Failed: #{e.class}: #{e.message}")
    raise
  end

  private

  def classify_and_parse(menuitem)
    section_name = menuitem.menusection&.name.to_s
    item_name = menuitem.name.to_s
    item_description = menuitem.description.to_s

    det = AlcoholDetectionService.detect(
      section_name: section_name,
      item_name: item_name,
      item_description: item_description,
    )

    text = [section_name, item_name, item_description].join(' ').downcase

    category = nil
    confidence = 0.0

    if det && det[:decided] && det[:alcoholic]
      if det[:classification].to_s == 'wine' || text.match?(/\b(wine|vino|vin)\b/)
        category = 'wine'
        confidence = [det[:confidence].to_f, 0.75].max
      elsif text.match?(/\b(whisky|whiskey)\b/) || WHISKEY_HINTS.any? { |k| text.include?(k) }
        category = 'whiskey'
        confidence = [det[:confidence].to_f, 0.7].max
      else
        category = det[:classification].to_s.presence || 'other_spirit'
        confidence = det[:confidence].to_f
      end
    elsif text.match?(/\b(whisky|whiskey)\b/) || WHISKEY_HINTS.any? { |k| text.include?(k) }
      category = 'whiskey'
      confidence = 0.55
    elsif text.match?(/\b(wine|vino|vin)\b/) || text.match?(VINTAGE_REGEX)
      category = 'wine'
      confidence = 0.55
    end

    parsed, parse_conf = parse_fields(menuitem, text)

    # Wine-specific deep parsing
    if category == 'wine'
      wine_fields, wine_conf = wine_parser.parse(menuitem)
      parsed.merge!(wine_fields) if wine_fields.is_a?(Hash)
      parse_conf = [parse_conf, wine_conf].max
      confidence = [confidence, wine_conf].max
    end

    # Whiskey-specific deep parsing
    if category == 'whiskey'
      whiskey_fields, whiskey_conf = whiskey_parser.parse(menuitem)
      parsed.merge!(whiskey_fields) if whiskey_fields.is_a?(Hash)
      parse_conf = [parse_conf, whiskey_conf].max
      confidence = [confidence, whiskey_conf].max
    end

    if category.blank? && llm_client_available?
      llm = llm_classify_fallback(section_name: section_name, item_name: item_name, item_description: item_description)
      if llm.is_a?(Hash) && llm['category'].present?
        category = llm['category'].to_s
        confidence = llm['confidence'].to_f
      end
    end

    [category, confidence, parsed, parse_conf]
  end

  def parse_fields(menuitem, text)
    parsed = {
      'name_raw' => menuitem.name.to_s,
      'description_raw' => menuitem.description.to_s,
      'price' => menuitem.price,
    }

    conf = 0.4

    if (m = AGE_REGEX.match(text))
      parsed['age_years'] = m[1].to_i
      conf += 0.2
    end

    if (m = VINTAGE_REGEX.match(text))
      parsed['vintage_year'] = m[1].to_i
      conf += 0.2
    end

    if (m = SIZE_ML_REGEX.match(text))
      parsed['size_ml'] = m[1].to_i
      conf += 0.1
    end

    if menuitem.abv.present?
      parsed['bottling_strength_abv'] = menuitem.abv.to_f
      conf += 0.2
    elsif (m = AlcoholDetectionService::ABV_REGEX.match(text))
      parsed['bottling_strength_abv'] = m[1].tr(',', '.').to_f
      conf += 0.2
    end

    conf = [conf, 1.0].min
    [parsed, conf]
  end

  def wine_parser
    @wine_parser ||= BeverageIntelligence::WineParser.new
  end

  def whiskey_parser
    @whiskey_parser ||= BeverageIntelligence::WhiskeyParser.new
  end

  def llm_client_available?
    Rails.configuration.x.openai_client.present?
  end

  def llm_classify_fallback(section_name:, item_name:, item_description:)
    client = Rails.configuration.x.openai_client
    return nil unless client

    system_msg = 'You are a precise classifier for restaurant menu lines. Output strict JSON.'
    user_msg = {
      section_name: section_name,
      item_name: item_name,
      item_description: item_description,
      allowed_categories: %w[whiskey wine other_spirit cocktail beer non_alcoholic food],
    }.to_json

    params = {
      model: ENV.fetch('OPENAI_CLASSIFIER_MODEL', 'gpt-4o-mini'),
      temperature: 0,
      messages: [
        { role: 'system', content: system_msg },
        { role: 'user', content: user_msg },
      ],
    }

    resp = client.chat(parameters: params)
    content = resp.dig('choices', 0, 'message', 'content').to_s.strip
    return nil if content.blank?

    JSON.parse(content)
  rescue StandardError
    nil
  end
end
