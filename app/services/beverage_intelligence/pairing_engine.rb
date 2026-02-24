# frozen_string_literal: true

module BeverageIntelligence
  class PairingEngine
    # Generate pairing recommendations for all drink items against food items
    # within a single menu.
    def generate_for_menu(menu)
      drink_items = menu.menuitems
                        .joins(:menusection)
                        .where('menusections.archived IS NOT TRUE')
                        .drink_items
                        .where(status: 'active')

      food_items = menu.menuitems
                       .joins(:menusection)
                       .where('menusections.archived IS NOT TRUE')
                       .where(itemtype: :food, status: 'active')

      return 0 if drink_items.empty? || food_items.empty?

      profiler = FlavorProfiler.new
      count = 0

      # Ensure all items have flavor profiles
      drink_items.find_each { |d| profiler.profile_product_for_menuitem(d) }
      food_items.find_each { |f| profiler.profile_food_item(f) }

      drink_items.find_each do |drink|
        drink_profile = drink.flavor_profile
        next unless drink_profile&.tags&.any?

        scored = food_items.filter_map do |food|
          next if food.id == drink.id
          food_profile = food.flavor_profile
          next unless food_profile&.tags&.any?

          scores = score_pairing(drink_profile, food_profile, drink, food)
          next if scores[:score] < 0.2

          { food: food, **scores }
        end

        # Top 3 complements
        top = scored.sort_by { |s| -s[:score] }.first(3)
        top.each do |match|
          save_pairing(drink, match[:food], match, 'complement')
          count += 1
        end

        # Best surprise match (high contrast, low complement)
        surprise = scored
          .select { |s| s[:contrast_score] > 0.5 && s[:complement_score] < 0.5 }
          .max_by { |s| s[:contrast_score] }

        if surprise && top.none? { |t| t[:food].id == surprise[:food].id }
          save_pairing(drink, surprise[:food], surprise, 'surprise')
          count += 1
        end
      end

      count
    end

    private

    def score_pairing(drink_profile, food_profile, drink, food)
      drink_tags = Set.new(drink_profile.tags)
      food_tags = Set.new(food_profile.tags)
      dm = drink_profile.structure_metrics || {}
      fm = food_profile.structure_metrics || {}

      # Complement score: shared flavor tags + harmonious structure
      shared_tags = (drink_tags & food_tags).size
      total_tags = [(drink_tags | food_tags).size, 1].max
      tag_overlap = shared_tags.to_f / total_tags

      complement = tag_overlap * 0.4

      # Body matching (similar body = good complement)
      body_diff = (dm['body'].to_f - fm['body'].to_f).abs
      complement += (1.0 - body_diff) * 0.2

      # Classic pairing rules
      complement += 0.15 if high_acid_cuts_fat?(dm, fm, food_tags)
      complement += 0.15 if sweetness_matches_dessert?(dm, food_tags)
      complement += 0.10 if smoke_meets_char?(drink_tags, food_tags)

      # Wine-specific pairing heuristics
      if wine_item?(drink)
        complement += wine_pairing_bonus(drink, food, drink_tags, food_tags, dm, fm)
      end

      # Contrast score: opposing flavors create interest
      contrast = 0.0
      contrast += 0.3 if drink_tags.include?('sweet') && food_tags.include?('saline')
      contrast += 0.3 if drink_tags.include?('smoke_peat') && food_tags.include?('sweet')
      contrast += 0.2 if drink_tags.include?('citrus') && food_tags.include?('creamy')
      contrast += 0.2 if drink_tags.include?('bitter') && food_tags.include?('sweet')

      # Risk flags
      risk_flags = []
      risk_flags << 'high_alcohol_vs_spice' if dm['alcohol_intensity'].to_f > 0.7 && food_tags.include?('spice')
      risk_flags << 'heavy_tannin_vs_fish' if dm['tannin'].to_f > 0.6 && food.name.to_s.downcase.match?(/\b(fish|salmon|cod|sea bass|trout)\b/)
      risk_flags << 'peat_vs_delicate' if dm['peat_level'].to_f > 0.5 && fm['body'].to_f < 0.3

      # Wine-specific risk flags
      if wine_item?(drink)
        risk_flags += wine_risk_flags(drink, food, drink_tags, food_tags, dm, fm)
      end

      # Penalize risky combos
      risk_penalty = risk_flags.size * 0.1

      total = [(complement * 0.6 + contrast * 0.4 - risk_penalty), 0.0].max
      total = [total, 1.0].min

      rationale = build_rationale(drink, food, drink_tags, food_tags, complement, contrast, risk_flags)

      {
        complement_score: complement.round(4),
        contrast_score: contrast.round(4),
        score: total.round(4),
        rationale: rationale,
        risk_flags: risk_flags,
      }
    end

    def high_acid_cuts_fat?(dm, fm, food_tags)
      dm['acidity'].to_f > 0.5 && (fm['body'].to_f > 0.6 || food_tags.include?('creamy'))
    end

    def sweetness_matches_dessert?(dm, food_tags)
      dm['sweetness_level'].to_f > 0.5 && food_tags.include?('sweet')
    end

    def smoke_meets_char?(drink_tags, food_tags)
      drink_tags.include?('smoke_peat') && food_tags.include?('smoke_peat')
    end

    def build_rationale(drink, food, drink_tags, food_tags, complement, contrast, risk_flags)
      parts = []
      shared = (drink_tags & food_tags)
      parts << "Shared flavors: #{shared.to_a.join(', ')}" if shared.any?
      parts << "Complementary pairing (#{(complement * 100).round}%)" if complement > 0.4
      parts << "Interesting contrast (#{(contrast * 100).round}%)" if contrast > 0.3
      parts << "Risks: #{risk_flags.join(', ')}" if risk_flags.any?
      parts.join('. ')
    end

    def wine_item?(menuitem)
      menuitem.wine?
    end

    def wine_color(menuitem)
      parsed = menuitem.sommelier_parsed_fields
      return nil unless parsed.is_a?(Hash)

      parsed['wine_color']
    end

    def wine_pairing_bonus(drink, food, drink_tags, food_tags, dm, fm)
      bonus = 0.0
      food_text = [food.name, food.description].compact_blank.join(' ').downcase
      color = wine_color(drink)

      # Tannin + protein/fat (red wine + red meat)
      if dm['tannin'].to_f > 0.5 && food_text.match?(/\b(steak|beef|lamb|venison|wagyu|ribs|pork)\b/)
        bonus += 0.15
      end

      # Acidity + rich/oily food (white wine + seafood/cream)
      if dm['acidity'].to_f > 0.5 && food_text.match?(/\b(salmon|tuna|lobster|cream|butter|risotto|pasta)\b/)
        bonus += 0.12
      end

      # Classic: red wine + red meat
      if color == 'red' && food_text.match?(/\b(steak|beef|lamb|venison|wagyu|duck|game)\b/)
        bonus += 0.10
      end

      # Classic: white wine + seafood/poultry
      if color == 'white' && food_text.match?(/\b(fish|seafood|shrimp|prawn|lobster|crab|oyster|chicken|turkey|veal)\b/)
        bonus += 0.10
      end

      # Rosé + light fare / Mediterranean
      if color == 'rosé' && food_text.match?(/\b(salad|bruschetta|antipast|mezze|grilled\s+vegetable|mediterranean|pizza|flatbread)\b/)
        bonus += 0.10
      end

      # Sparkling + appetizers/fried/salty
      if color == 'sparkling' && food_text.match?(/\b(appetizer|starter|canap|fried|salty|oyster|caviar|chip|crispy)\b/)
        bonus += 0.12
      end

      # Dessert wine + dessert
      if color == 'dessert' && food_tags.include?('sweet')
        bonus += 0.15
      end

      # Fortified wine + cheese/chocolate
      if color == 'fortified' && food_text.match?(/\b(cheese|chocolate|nuts|dried\s+fruit|blue\s+cheese|stilton)\b/)
        bonus += 0.12
      end

      # Body matching bonus for wines
      body_match = 1.0 - (dm['body'].to_f - fm['body'].to_f).abs
      bonus += body_match * 0.08 if body_match > 0.7

      bonus
    end

    def wine_risk_flags(drink, food, drink_tags, food_tags, dm, fm)
      flags = []
      food_text = [food.name, food.description].compact_blank.join(' ').downcase
      color = wine_color(drink)

      # Heavy red with delicate fish
      if color == 'red' && dm['tannin'].to_f > 0.5 && food_text.match?(/\b(white\s+fish|sole|halibut|cod|sea\s+bass)\b/)
        flags << 'tannic_red_vs_delicate_fish'
      end

      # Very oaky wine + light/fresh dishes
      if drink_tags.include?('vanilla_oak') && fm['body'].to_f < 0.3
        flags << 'oaky_wine_vs_delicate_dish'
      end

      # Sweet wine + savoury main
      if dm['sweetness_level'].to_f > 0.6 && !food_tags.include?('sweet') && fm['body'].to_f > 0.5
        flags << 'sweet_wine_vs_savoury_main'
      end

      flags
    end

    def save_pairing(drink, food, scores, pairing_type)
      rec = PairingRecommendation.find_or_initialize_by(
        drink_menuitem_id: drink.id,
        food_menuitem_id: food.id,
      )
      rec.assign_attributes(
        complement_score: scores[:complement_score],
        contrast_score: scores[:contrast_score],
        score: scores[:score],
        rationale: scores[:rationale],
        risk_flags: scores[:risk_flags],
        pairing_type: pairing_type,
      )
      rec.save!
    rescue ActiveRecord::RecordNotUnique
      # Race condition: another process created the same pairing
      nil
    end
  end
end
