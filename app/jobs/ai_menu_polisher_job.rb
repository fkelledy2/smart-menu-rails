require 'sidekiq'
require 'json'

class AiMenuPolisherJob
  include Sidekiq::Job

  sidekiq_options queue: 'default', retry: 3

  def perform(menu_id)
    menu = Menu.includes(menusections: [:menuitems]).find_by(id: menu_id)
    return unless menu

    restaurant = menu.restaurant
    total_items = menu.menuitems.count
    processed = 0

    # Init progress
    set_progress('queued', 0, total_items, menu_id)

    ActiveRecord::Base.transaction do
      # 1) Reorder sections by heuristic (starters -> mains -> desserts -> drinks)
      reorder_sections!(menu)

      # 2) Polish sections and items
      allergyn_catalog = Allergyn.where(restaurant: restaurant).to_a

      menu.menusections.order(:sequence).each do |section|
        section.name = normalize_title(section.name)
        section.description = normalize_sentence(section.description)
        section.save! if section.changed?

        section.menuitems.order(:sequence).each do |mi|
          # Clean up names/descriptions
          mi.name = normalize_title(mi.name)
          if mi.description.blank?
            mi.description = mi.name
          end
          # If name and description are identical, use LLM to generate a better description
          if texts_equal?(mi.name, mi.description)
            begin
              gen = generate_description_via_llm(
                item_name: mi.name,
                section_name: section.name,
                section_description: section.description
              )
              mi.description = gen if gen.present?
            rescue => e
              Rails.logger.warn("[AIMenuPolisherJob] LLM description failed for item ##{mi.id}: #{e.class}: #{e.message}")
            end
          end
          mi.description = normalize_sentence(mi.description)

          # Alcohol detection
          begin
            det = AlcoholDetectionService.detect(
              section_name: section.name.to_s,
              item_name: mi.name.to_s,
              # Expand context by including section description into the item_description signal
              item_description: [mi.description.to_s, section.description.to_s].reject(&:blank?).join(". ")
            )
            # Decide whether to call LLM: always when forced, otherwise only if undecided
            llm_det = nil
            if llm_alcohol_enabled? && (llm_alcohol_forced? || !(det && det[:decided]))
              llm_det = generate_alcohol_decision_via_llm(
                item_name: mi.name.to_s,
                item_description: mi.description.to_s,
                section_name: section.name.to_s,
                section_description: section.description.to_s
              )
            end

            # Combine results: prefer heuristics when they decide, but set alcoholic=true if either says true
            heur_says = det && det[:decided] ? det[:alcoholic] : nil
            llm_says = llm_det && llm_det[:decided] ? llm_det[:alcoholic] : nil
            final_alcoholic = (heur_says == true) || (llm_says == true)

            if final_alcoholic
              # Choose classification/abv preferring heuristics when it decided alcoholic, else LLM
              chosen_class = if heur_says == true && det[:classification].present?
                               det[:classification]
                             else
                               llm_det && llm_det[:classification].presence
                             end
              chosen_abv = if heur_says == true && det.key?(:abv)
                             det[:abv]
                           else
                             llm_det && llm_det[:abv]
                           end

              source = if heur_says == true && llm_says == true
                         'heuristics+LLM'
                       elsif heur_says == true
                         'heuristics'
                       elsif llm_says == true
                         'LLM'
                       else
                         'unknown'
                       end

              Rails.logger.warn("[AIMenuPolisherJob] alcohol(#{source})=true item=##{mi.id} name='#{mi.name}' section='#{section.name}' class='#{chosen_class}' abv='#{chosen_abv}'")
              set_progress('running', processed, total_items, menu_id, message: "Alcohol detected (#{source})", extra: { current_item_name: mi.name })

              mi.alcoholic = true
              mi.abv = chosen_abv if !chosen_abv.nil?
              mi.alcohol_classification = chosen_class if chosen_class.present?
            else
              # Neither heuristics nor LLM flagged alcoholic; try fallback by section hints
              sec_name = section.name.to_s
              sec_class = AlcoholDetectionService.section_class_from_text(sec_name)
              if sec_class.present? || sec_name.to_s.downcase.match?(/\b(drinks?|beverages?)\b/)
                Rails.logger.warn("[AIMenuPolisherJob] alcohol(fallback)=true item=##{mi.id} name='#{mi.name}' section='#{section.name}' class='#{sec_class.presence || 'other'}'")
                set_progress('running', processed, total_items, menu_id, message: "Alcohol detected (fallback)", extra: { current_item_name: mi.name })
                mi.alcoholic = true
                mi.alcohol_classification = (sec_class.presence || 'other')
              else
                mi.alcoholic = false
                # keep silence per requirement (log only when alcoholic)
              end
            end
          rescue => e
            Rails.logger.warn("[AIMenuPolisherJob] alcohol detect failed for item ##{mi.id}: #{e.class}: #{e.message}")
          end

          # Allergen mapping: naive keyword match against catalog names
          begin
            desired_names = detect_allergens_from_text(allergyn_catalog, mi)
            map_item_allergyns!(mi, desired_names, restaurant)
          rescue => e
            Rails.logger.warn("[AIMenuPolisherJob] allergen map failed for item ##{mi.id}: #{e.class}: #{e.message}")
          end

          mi.save! if mi.changed?

          processed += 1
          set_progress('running', processed, total_items, menu_id, message: "Polished '#{mi.name}' (#{processed}/#{total_items})", extra: { current_item_name: mi.name })
        end
      end
    end

    # Invalidate caches
    AdvancedCacheService.invalidate_menu_caches(menu.id)
    AdvancedCacheService.invalidate_restaurant_caches(menu.restaurant.id)

    set_progress('completed', total_items, total_items, menu_id)
  rescue => e
    Rails.logger.error("[AIMenuPolisherJob] Error polishing menu ##{menu_id}: #{e.class}: #{e.message}")
    set_progress('failed', processed, total_items, menu_id, message: e.message)
    raise
  end

  private

  def update_progress(payload)
    Sidekiq.redis do |r|
      existing = {}
      begin
        json = r.get("polish:#{jid}")
        existing = json.present? ? JSON.parse(json) : {}
      rescue StandardError
        existing = {}
      end

      merged = existing.merge(payload.stringify_keys)
      r.setex("polish:#{jid}", 24 * 3600, merged.to_json)
    end
  rescue => e
    Rails.logger.warn("[AIMenuPolisherJob] Failed to write progress for #{jid}: #{e.class}: #{e.message}")
  end

  def append_progress_log(message)
    Sidekiq.redis do |r|
      json = r.get("polish:#{jid}")
      payload = json.present? ? JSON.parse(json) : {}
      log = Array(payload['log'])
      log << { at: Time.current.iso8601, message: message }
      payload['log'] = log.last(50)
      r.setex("polish:#{jid}", 24 * 3600, payload.to_json)
    end
  rescue => e
    Rails.logger.warn("[AIMenuPolisherJob] Failed to append progress log for #{jid}: #{e.class}: #{e.message}")
  end

  def set_progress(status, current, total, menu_id, message: nil, extra: nil)
    payload = {
      status: status,
      current: current,
      total: total,
      message: message || 'AI polishing in progress',
      menu_id: menu_id
    }.merge(extra.is_a?(Hash) ? extra : {})

    update_progress(payload)

    msg = payload[:message].to_s
    if payload[:current_item_name].present?
      append_progress_log("#{payload[:current_item_name]} — #{msg}")
    elsif msg.present?
      append_progress_log(msg)
    end
  rescue => e
    Rails.logger.warn("[AIMenuPolisherJob] Failed to set progress: #{e.message}")
  end

  def normalize_title(text)
    s = text.to_s.strip.gsub(/\s+/, ' ')
    return s if s.blank?
    s.titleize
  end

  def normalize_sentence(text)
    s = text.to_s.strip.gsub(/\s+/, ' ')
    return s if s.blank?
    s = s.downcase
    s[0] = s[0].upcase if s[0]
    s
  end

  def reorder_sections!(menu)
    priority = {
      'starter' => 10, 'starters' => 10, 'antipasti' => 10, 'appetizer' => 10, 'appetizers' => 10,
      'salad' => 20, 'soups' => 20,
      'main' => 30, 'mains' => 30, 'secondi' => 30, 'piatti principali' => 30,
      'side' => 40, 'sides' => 40, 'contorni' => 40,
      'dessert' => 50, 'desserts' => 50, 'dolci' => 50,
      'drinks' => 60, 'beverages' => 60, 'wine' => 60, 'beer' => 60, 'cocktails' => 60
    }
    seq = 1
    menu.menusections.sort_by { |ms|
      key = ms.name.to_s.downcase
      pr = priority.find { |k, _| key.include?(k) }&.last || 999
      [pr, ms.sequence || 999]
    }.each do |ms|
      # Avoid unnecessary updates (and noisy N+1 warnings)
      if ms.sequence.to_i != seq
        ms.update_column(:sequence, seq)
      end
      seq += 1
    end
  end

  def detect_allergens_from_text(allergyn_catalog, mi)
    text = [mi.name, mi.description].compact.map(&:to_s).join(' ').downcase
    names = []
    allergyn_catalog.each do |a|
      n = a.name.to_s.downcase
      next if n.blank?
      names << n if text.include?(n)
    end
    names.uniq
  end

  # Minimal re-implementation inspired by ImportToMenu#map_item_allergyns!
  def map_item_allergyns!(menuitem, allergen_names, restaurant)
    desired = Array(allergen_names).map { |n| n.to_s.strip.downcase }.uniq
    return if desired.empty?

    allergyns = Allergyn.where(restaurant: restaurant).select { |a| desired.include?(a.name.to_s.strip.downcase) }

    current_ids = MenuitemAllergynMapping.where(menuitem_id: menuitem.id).pluck(:allergyn_id).to_set
    desired_ids = allergyns.to_set(&:id)

    (desired_ids - current_ids).each do |aid|
      MenuitemAllergynMapping.create!(menuitem_id: menuitem.id, allergyn_id: aid)
    end

    (current_ids - desired_ids).each do |aid|
      MenuitemAllergynMapping.where(menuitem_id: menuitem.id, allergyn_id: aid).delete_all
    end
  end

  # Compare two strings for equality ignoring case and surrounding whitespace
  def texts_equal?(a, b)
    a.to_s.strip.casecmp?(b.to_s.strip)
  end

  # Use the configured OpenAI chat client to generate a concise description
  # Returns nil if client not configured or response empty
  def generate_description_via_llm(item_name:, section_name:, section_description: nil)
    client = Rails.configuration.x.openai_client
    return nil unless client

    system_msg = 'You are a culinary copywriter. Write a concise, appetizing, single-sentence menu description (max 24 words). No emojis. No allergens. No pricing.'
    context_bits = []
    context_bits << "Section: #{section_name}." if section_name.present?
    context_bits << "Section description: #{section_description}." if section_description.present?
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
        { role: 'user', content: user_msg }
      ]
    }

    begin
      resp = client.chat(parameters: params)
      content = resp.dig('choices', 0, 'message', 'content').to_s.strip
      return nil if content.blank?
      content.gsub(/[\s\n]+/, ' ').strip
    rescue => e
      Rails.logger.warn("[AIMenuPolisherJob] OpenAI chat error: #{e.message}")
      nil
    end
  end

  # Optional: ask LLM to decide alcohol presence when heuristics are undecided
  # Returns a hash similar to AlcoholDetectionService or nil when disabled/unavailable
  def generate_alcohol_decision_via_llm(item_name:, item_description:, section_name:, section_description: nil)
    return nil unless llm_alcohol_enabled?
    client = Rails.configuration.x.openai_client
    return nil unless client

    system_msg = 'You are a precise classifier for menu items. Determine whether the item contains alcohol.'
    user_prompt = <<~PROMPT.strip
      Decide if this menu item contains alcohol. Reply ONLY with compact JSON matching this schema:
      {"alcoholic": true|false, "classification": "wine|beer|spirit|liqueur|cocktail|cider|sake|mead|non_alcoholic|other", "abv": number|null}

      Section: #{section_name}
      Section description: #{section_description}
      Item name: #{item_name}
      Item description: #{item_description}
    PROMPT

    params = {
      model: ENV['OPENAI_MODEL'].presence || 'gpt-3.5-turbo',
      temperature: 0.0,
      messages: [
        { role: 'system', content: system_msg },
        { role: 'user', content: user_prompt }
      ]
    }

    begin
      resp = client.chat(parameters: params)
      content = resp.dig('choices', 0, 'message', 'content').to_s.strip
      return nil if content.blank?

      # Best effort to extract JSON
      json_str = content[/\{.*\}/m] || content
      data = JSON.parse(json_str) rescue nil
      return nil unless data.is_a?(Hash) && data.key?('alcoholic')

      decided = true
      alcoholic = !!data['alcoholic']
      classification = data['classification'].to_s.presence
      abv = data['abv']
      abv = abv.to_f if abv.is_a?(String) && abv.match?(/\d/)

      { decided: decided, alcoholic: alcoholic, classification: classification, abv: abv, confidence: 0.7, note: 'llm tiebreaker' }
    rescue => e
      Rails.logger.warn("[AIMenuPolisherJob] OpenAI alcohol tiebreaker error: #{e.message}")
      nil
    end
  end

  def llm_alcohol_enabled?
    v = ENV['AI_POLISH_USE_LLM_ALCOHOL']
    return true if v.nil? || v.strip == ''
    v.to_s.downcase == 'true'
  end

  def llm_alcohol_forced?
    ENV['AI_POLISH_FORCE_LLM_ALCOHOL'].to_s.downcase == 'true'
  end
end
