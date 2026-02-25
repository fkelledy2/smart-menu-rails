# frozen_string_literal: true

module BeverageIntelligence
  class FlavorProfiler
    CONTROLLED_TAGS = FlavorProfile::CONTROLLED_TAGS

    # Profile a product using its enrichment data
    def profile_product(product)
      enrichment = product.product_enrichments.order(created_at: :desc).first
      return nil unless enrichment

      payload = enrichment.payload_json.is_a?(Hash) ? enrichment.payload_json : {}
      tasting_notes = payload['tasting_notes'] || {}
      description = [
        tasting_notes['nose'],
        tasting_notes['palate'],
        tasting_notes['finish'],
        payload['production_notes'],
        payload['brand_story'],
      ].compact_blank.join('. ')

      return rules_profile_product(product, payload, description) if description.present?

      nil
    end

    # Profile a drink menu item via its linked product
    def profile_product_for_menuitem(menuitem)
      return menuitem.flavor_profile if menuitem.flavor_profile.present?

      link = menuitem.menu_item_product_links.first
      if link&.product
        profile = profile_product(link.product)
        # Copy product profile to menuitem if available
        if profile
          return build_or_update_profile(
            menuitem,
            tags: profile.tags,
            metrics: profile.structure_metrics,
            provenance: "from_product_#{link.product.id}",
          )
        end
      end

      # Fallback: profile from item text directly
      text = [menuitem.name, menuitem.description].compact_blank.join('. ')
      return nil if text.blank?

      # Wine items get enhanced profiling from parsed fields
      if menuitem.wine?
        return profile_wine_item(menuitem, text)
      end

      tags = extract_drink_tags_from_text(text)
      metrics = { 'body' => 0.5, 'sweetness_level' => 0.4, 'alcohol_intensity' => 0.5 }
      build_or_update_profile(menuitem, tags: tags, metrics: metrics, provenance: 'text_rules_v1')
    end

    # Profile a food menu item using its name + description
    def profile_food_item(menuitem)
      text = [menuitem.name, menuitem.description].compact_blank.join('. ')
      return nil if text.blank?

      tags = extract_food_tags(text)
      metrics = estimate_food_metrics(text, tags)

      build_or_update_profile(menuitem, tags: tags, metrics: metrics, provenance: 'rules_v1')
    end

    # LLM-based profiling (fallback for products with thin enrichment)
    def llm_profile(entity, description)
      client = openai_client
      return nil unless client

      prompt = build_tagging_prompt(description)

      resp = client.chat(parameters: {
        model: ENV.fetch('OPENAI_SOMMELIER_MODEL', 'gpt-4o-mini'),
        temperature: 0,
        messages: [
          { role: 'system', content: 'You output strict JSON only.' },
          { role: 'user', content: prompt },
        ],
      })

      content = resp.dig('choices', 0, 'message', 'content').to_s.strip
      return nil if content.blank?

      parsed = JSON.parse(content)
      tags = Array(parsed['tags']).select { |t| CONTROLLED_TAGS.include?(t) }
      metrics = parsed['structure_metrics'].is_a?(Hash) ? parsed['structure_metrics'] : {}

      build_or_update_profile(entity, tags: tags, metrics: metrics, provenance: 'llm_v1')
    rescue StandardError => e
      Rails.logger.warn("[FlavorProfiler] LLM profiling failed: #{e.class}: #{e.message}")
      nil
    end

    private

    def rules_profile_product(product, payload, description)
      text = description.downcase
      tags = []

      # Match controlled tags against tasting notes
      tag_patterns = {
        'sweet' => /\b(sweet|honey|sugar|caramel|toffee|butterscotch|vanilla|maple)\b/,
        'smoke_peat' => /\b(smok[ey]|peat[ey]?|campfire|bonfire|ash|charr?ed|kiln)\b/,
        'spice' => /\b(spic[ey]|pepper|cinnamon|clove|ginger|nutmeg|cardamom|chili|chilli)\b/,
        'vanilla_oak' => /\b(vanilla|oak|wood[ey]?|barrel|cask|cedar|sandalwood)\b/,
        'dried_fruit' => /\b(dried fruit|raisin|fig|date|prune|sultana|currant)\b/,
        'citrus' => /\b(citrus|lemon|lime|orange|grapefruit|zest|tangerine|bergamot)\b/,
        'floral' => /\b(floral|flower|rose|violet|lavender|jasmine|blossom|elderflower)\b/,
        'nutty' => /\b(nut[ty]?|almond|walnut|hazelnut|pecan|marzipan|praline)\b/,
        'saline' => /\b(salin[ey]?|salt[ey]?|brine|briny|sea|maritime|coastal|iodine)\b/,
        'umami' => /\b(umami|savou?ry|meaty|soy|miso)\b/,
        'bitter' => /\b(bitter|dark chocolate|espresso|coffee|cocoa)\b/,
        'creamy' => /\b(cream[ey]?|butter[ey]?|silky|smooth|velvet[ey]?|rich)\b/,
        'tannic' => /\b(tannic|tannin|grippy|astringent|firm|structured)\b/,
        'herbal' => /\b(herb[al]?|thyme|rosemary|mint|sage|basil|eucalyptus|juniper)\b/,
        'earthy' => /\b(earth[ey]?|soil|mushroom|truffle|forest|moss|loam|mineral)\b/,
        'tropical' => /\b(tropical|mango|pineapple|passion\s?fruit|guava|papaya|lychee)\b/,
        'stone_fruit' => /\b(stone fruit|peach|apricot|plum|nectarine|cherry)\b/,
        'berry' => /\b(berr[ey]|strawberr[ey]|blueberr[ey]|raspberr[ey]|blackberr[ey]|cranberr[ey])\b/,
        'chocolate' => /\b(chocolat[ey]?|cocoa|cacao)\b/,
        'caramel' => /\b(caramel|toffee|butterscotch|fudge|treacle)\b/,
        'honey' => /\b(honey|honeycomb|beeswax|nectar)\b/,
      }

      tag_patterns.each do |tag, pattern|
        tags << tag if text.match?(pattern)
      end

      tags = tags.uniq & CONTROLLED_TAGS

      metrics = estimate_drink_metrics(product, payload, text)

      build_or_update_profile(product, tags: tags, metrics: metrics, provenance: 'rules_v1')
    end

    def estimate_drink_metrics(product, payload, text)
      metrics = {}

      abv = payload['abv'].to_f
      abv = product.attributes_json['abv'].to_f if abv.zero? && product.attributes_json.is_a?(Hash)
      metrics['alcohol_intensity'] = if abv.positive?
                                       [(abv / 60.0).round(2), 1.0].min
                                     else
                                       product.product_type == 'wine' ? 0.2 : 0.5
                                     end

      metrics['body'] = if text.match?(/\b(full[- ]?bodied|heavy|rich|bold|robust)\b/)
                          0.8
                        elsif text.match?(/\b(light[- ]?bodied|light|delicate|thin|crisp)\b/)
                          0.3
                        else
                          0.5
                        end

      metrics['sweetness_level'] = if text.match?(/\b(sweet|dessert|luscious|honeyed)\b/)
                                     0.7
                                   elsif text.match?(/\b(dry|brut|bone[- ]dry|austere)\b/)
                                     0.2
                                   else
                                     0.4
                                   end

      metrics['finish_length'] = if text.match?(/\b(long|lingering|endless|persistent)\b/)
                                   0.8
                                 elsif text.match?(/\b(short|brief|quick|clean)\b/)
                                   0.3
                                 else
                                   0.5
                                 end

      metrics['peat_level'] = if text.match?(/\b(heavily? peated|peat)\b/)
                                0.8
                              elsif text.match?(/\b(lightly? peated|hint of smoke)\b/)
                                0.4
                              else
                                0.0
                              end

      if product.product_type == 'wine'
        metrics['acidity'] = text.match?(/\b(acid|crisp|tart|zesty|bright)\b/) ? 0.7 : 0.4
        metrics['tannin'] = text.match?(/\b(tannic|tannin|grippy|structured)\b/) ? 0.7 : 0.3
      end

      metrics
    end

    def extract_drink_tags_from_text(text)
      t = text.downcase
      tags = []
      # Reuse the same tag patterns as rules_profile_product
      {
        'sweet' => /\b(sweet|honey|sugar|caramel|toffee|butterscotch|vanilla|maple)\b/,
        'smoke_peat' => /\b(smok[ey]|peat[ey]?|campfire|bonfire|ash|charr?ed|kiln)\b/,
        'spice' => /\b(spic[ey]|pepper|cinnamon|clove|ginger|nutmeg)\b/,
        'vanilla_oak' => /\b(vanilla|oak|wood[ey]?|barrel|cask|cedar)\b/,
        'dried_fruit' => /\b(dried fruit|raisin|fig|date|prune|sultana)\b/,
        'citrus' => /\b(citrus|lemon|lime|orange|grapefruit|zest)\b/,
        'floral' => /\b(floral|flower|rose|violet|lavender|jasmine)\b/,
        'nutty' => /\b(nut[ty]?|almond|walnut|hazelnut|marzipan)\b/,
        'creamy' => /\b(cream[ey]?|butter[ey]?|silky|smooth|velvet)\b/,
        'herbal' => /\b(herb[al]?|thyme|rosemary|mint|sage|juniper)\b/,
      }.each { |tag, pattern| tags << tag if t.match?(pattern) }
      tags.uniq & CONTROLLED_TAGS
    end

    def profile_wine_item(menuitem, text)
      t = text.downcase
      parsed = menuitem.sommelier_parsed_fields.is_a?(Hash) ? menuitem.sommelier_parsed_fields : {}
      color = parsed['wine_color']
      grapes = Array(parsed['grape_variety'])

      tags = extract_drink_tags_from_text(t)

      # Add wine-specific tags from grape characteristics
      tags += grape_flavor_tags(grapes.first) if grapes.any?

      # Color-based tag additions
      case color
      when 'red'
        tags += %w[tannic berry] unless tags.any? { |t2| %w[tannic berry stone_fruit].include?(t2) }
      when 'white'
        tags += %w[citrus floral] unless tags.any? { |t2| %w[citrus floral tropical].include?(t2) }
      when 'rosé'
        tags += %w[berry floral citrus] unless tags.any? { |t2| %w[berry floral citrus].include?(t2) }
      when 'sparkling'
        tags += %w[citrus creamy] unless tags.any? { |t2| %w[citrus creamy].include?(t2) }
      when 'dessert'
        tags += %w[sweet honey dried_fruit] unless tags.include?('sweet')
      when 'fortified'
        tags += %w[sweet nutty caramel] unless tags.include?('sweet')
      end

      tags = tags.uniq & CONTROLLED_TAGS
      metrics = estimate_wine_metrics(t, color, grapes, parsed)

      build_or_update_profile(menuitem, tags: tags, metrics: metrics, provenance: 'wine_rules_v1')
    end

    def grape_flavor_tags(grape)
      grape_tag_map = {
        'cabernet sauvignon' => %w[tannic berry vanilla_oak],
        'merlot' => %w[berry creamy stone_fruit],
        'pinot noir' => %w[berry earthy floral],
        'syrah' => %w[spice berry smoke_peat],
        'shiraz' => %w[spice berry smoke_peat],
        'malbec' => %w[berry spice chocolate],
        'tempranillo' => %w[berry vanilla_oak earthy],
        'sangiovese' => %w[berry earthy herbal],
        'nebbiolo' => %w[tannic floral earthy],
        'grenache' => %w[berry spice herbal],
        'primitivo' => %w[berry sweet spice],
        'zinfandel' => %w[berry spice sweet],
        'chardonnay' => %w[citrus creamy vanilla_oak],
        'sauvignon blanc' => %w[citrus herbal floral],
        'riesling' => %w[citrus floral sweet],
        'pinot grigio' => %w[citrus floral],
        'gewürztraminer' => %w[floral spice tropical],
        'viognier' => %w[floral stone_fruit creamy],
        'chenin blanc' => %w[citrus honey floral],
        'albariño' => %w[citrus saline floral],
        'verdejo' => %w[citrus herbal],
        'vermentino' => %w[citrus herbal saline],
        'muscadet' => %w[citrus saline],
      }
      grape_tag_map[grape.to_s.downcase] || []
    end

    def estimate_wine_metrics(text, color, grapes, parsed)
      metrics = {}

      # Alcohol intensity
      abv = parsed['bottling_strength_abv'].to_f
      metrics['alcohol_intensity'] = abv.positive? ? [(abv / 20.0).round(2), 1.0].min : 0.2

      # Body from color/grape defaults
      metrics['body'] = case color
                        when 'red' then text.match?(/\b(full|bold|rich|robust)\b/) ? 0.8 : 0.6
                        when 'white' then text.match?(/\b(full|rich|oaked)\b/) ? 0.6 : 0.35
                        when 'rosé' then 0.35
                        when 'sparkling' then 0.3
                        when 'dessert' then 0.7
                        when 'fortified' then 0.8
                        else 0.5
                        end

      # Sweetness
      metrics['sweetness_level'] = if text.match?(/\b(sweet|dessert|luscious|doux|dolce|amabile)\b/)
                                     0.7
                                   elsif text.match?(/\b(dry|brut|secco|seco|trocken|bone.?dry)\b/)
                                     0.15
                                   elsif color == 'dessert'
                                     0.8
                                   elsif %w[riesling gewürztraminer chenin blanc].include?(grapes.first)
                                     0.45
                                   else
                                     0.25
                                   end

      # Acidity
      metrics['acidity'] = if text.match?(/\b(acid|crisp|tart|zesty|bright|fresh|racy)\b/)
                             0.7
                           elsif %w[sauvignon blanc riesling albariño muscadet].include?(grapes.first)
                             0.7
                           elsif %w[white sparkling].include?(color)
                             0.55
                           else
                             0.4
                           end

      # Tannin
      metrics['tannin'] = if text.match?(/\b(tannic|tannin|grippy|structured|firm)\b/)
                            0.7
                          elsif %w[cabernet sauvignon nebbiolo tempranillo].include?(grapes.first)
                            0.7
                          elsif color == 'red'
                            0.5
                          else
                            0.15
                          end

      # Finish
      metrics['finish_length'] = text.match?(/\b(long|lingering|persistent)\b/) ? 0.8 : 0.5
      metrics['peat_level'] = 0.0 # wines don't have peat

      metrics
    end

    def extract_food_tags(text)
      t = text.downcase
      tags = []

      tags << 'sweet' if t.match?(/\b(sweet|dessert|sugar|honey|caramel|chocolate|cake|pastry|tart|crème)\b/)
      tags << 'spice' if t.match?(/\b(spic[ey]|chili|chilli|pepper|curry|harissa|kimchi|sriracha|jalapeño)\b/)
      tags << 'umami' if t.match?(/\b(umami|soy|miso|aged cheese|parmesan|truffle|mushroom|anchov)\b/)
      tags << 'saline' if t.match?(/\b(salt[ey]?|briny|oyster|caviar|anchov|cured|prosciutto|bresaola)\b/)
      tags << 'creamy' if t.match?(/\b(cream[ey]?|butter[ey]?|brie|camembert|burrata|risotto|mousse)\b/)
      tags << 'citrus' if t.match?(/\b(citrus|lemon|lime|orange|grapefruit|yuzu|ceviche)\b/)
      tags << 'earthy' if t.match?(/\b(earth[ey]?|root|beet|mushroom|truffle|lentil)\b/)
      tags << 'smoke_peat' if t.match?(/\b(smoked|charred|grilled|barbecue|bbq)\b/)
      tags << 'herbal' if t.match?(/\b(herb|basil|thyme|rosemary|cilantro|dill|mint|pesto)\b/)
      tags << 'bitter' if t.match?(/\b(bitter|radicchio|endive|arugula|rocket|dark chocolate)\b/)
      tags << 'nutty' if t.match?(/\b(nut|almond|walnut|pistachio|hazelnut|peanut|tahini)\b/)

      tags.uniq & CONTROLLED_TAGS
    end

    def estimate_food_metrics(text, tags)
      t = text.downcase
      {
        'body' => t.match?(/\b(steak|lamb|pork|ribs|duck|wagyu|braised|stew)\b/) ? 0.8 : 0.4,
        'sweetness_level' => tags.include?('sweet') ? 0.7 : 0.2,
        'acidity' => t.match?(/\b(vinaigrette|pickle|ceviche|citrus|tomato)\b/) ? 0.7 : 0.3,
      }
    end

    def build_or_update_profile(entity, tags:, metrics:, provenance:)
      profile = FlavorProfile.find_or_initialize_by(
        profilable_type: entity.class.name,
        profilable_id: entity.id,
      )
      profile.assign_attributes(
        tags: tags,
        structure_metrics: metrics,
        provenance: provenance,
      )
      profile.save!
      profile
    end

    def build_tagging_prompt(description)
      <<~PROMPT
        Analyze the following beverage or food description and extract flavor tags and structure metrics.

        CONTROLLED TAGS (only use these): #{CONTROLLED_TAGS.join(', ')}

        STRUCTURE METRICS (each 0.0-1.0):
        - alcohol_intensity, body, sweetness_level, finish_length, peat_level, acidity, tannin

        Return JSON: { "tags": [...], "structure_metrics": { ... } }

        DESCRIPTION:
        #{description}
      PROMPT
    end

    def openai_client
      Rails.configuration.x.openai_client
    end
  end
end
