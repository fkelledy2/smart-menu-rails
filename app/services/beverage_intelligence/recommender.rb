# frozen_string_literal: true

module BeverageIntelligence
  class Recommender
    # Generate "If you like X, you'll love Y" recommendations for products
    # that appear on a given menu.
    def generate_for_menu(menu)
      product_ids = MenuItemProductLink
        .joins(menuitem: { menusection: :menu })
        .where(menus: { id: menu.id })
        .distinct
        .pluck(:product_id)

      products = Product.where(id: product_ids).includes(:flavor_profile)
      return 0 if products.size < 2

      count = 0

      products.each do |product|
        next unless product.flavor_profile&.tags&.any?

        candidates = products.reject { |p| p.id == product.id }
        scored = candidates.filter_map do |candidate|
          next unless candidate.flavor_profile&.tags&.any?

          score = similarity_score(product.flavor_profile, candidate.flavor_profile)
          next if score < 0.2

          # Price tier filter: avoid huge jumps
          price_ok = price_tier_compatible?(product, candidate, menu)
          next unless price_ok

          rationale = build_rationale(product, candidate, score)
          { candidate: candidate, score: score, rationale: rationale }
        end

        # Diversity: pick top 3 but avoid all being same type
        top = apply_diversity(scored.sort_by { |s| -s[:score] }, product)

        top.each do |match|
          save_recommendation(product, match[:candidate], match[:score], match[:rationale])
          count += 1
        end
      end

      count
    end

    # Recommend wines for a guest based on wine-specific preferences
    def recommend_wines_for_guest(menu:, preferences:, limit: 3)
      wine_color_pref = preferences[:wine_color] # red, white, rosé, sparkling, no_preference
      body_pref       = preferences[:body]        # light, medium, full
      taste           = preferences[:taste]       # sweet, dry, fruity
      budget          = preferences[:budget]      # 1, 2, 3

      wine_items = menu.menuitems
                       .joins(:menusection)
                       .where('menusections.archived IS NOT TRUE')
                       .where(sommelier_category: 'wine', status: 'active')
                       .includes(:flavor_profile, menu_item_product_links: { product: :product_enrichments })

      scored = wine_items.filter_map do |item|
        profile = item.flavor_profile
        next unless profile&.tags&.any?

        score = wine_preference_score(profile, wine_color_pref, body_pref, taste, budget, item)
        next if score <= 0

        best_pairing = PairingRecommendation
          .where(drink_menuitem_id: item.id)
          .order(score: :desc)
          .first

        parsed = item.sommelier_parsed_fields.is_a?(Hash) ? item.sommelier_parsed_fields : {}

        {
          menuitem: item,
          score: score,
          tags: profile.tags.first(3),
          best_pairing: best_pairing,
          enrichment: item_enrichment(item),
          wine_color: parsed['wine_color'],
          grape_variety: Array(parsed['grape_variety']).first,
          appellation: parsed['appellation'],
          vintage_year: parsed['vintage_year'],
          classification: parsed['classification'],
        }
      end

      scored.sort_by { |s| -s[:score] }.first(limit)
    end

    # Recommend drinks for a guest based on preferences (tap-driven flow)
    def recommend_for_guest(menu:, preferences:, limit: 3)
      smoky = preferences[:smoky]
      taste = preferences[:taste] # sweet, dry, spicy
      budget = preferences[:budget] # 1, 2, 3

      drink_items = menu.menuitems
                        .joins(:menusection)
                        .where('menusections.archived IS NOT TRUE')
                        .where.not(sommelier_category: [nil, ''])
                        .where(status: 'active')
                        .includes(:flavor_profile, menu_item_product_links: { product: :product_enrichments })

      scored = drink_items.filter_map do |item|
        profile = item.flavor_profile
        next unless profile&.tags&.any?

        score = preference_score(profile, smoky, taste, budget, item)
        next if score <= 0

        # Get best pairing for this drink
        best_pairing = PairingRecommendation
          .where(drink_menuitem_id: item.id)
          .order(score: :desc)
          .first

        {
          menuitem: item,
          score: score,
          tags: profile.tags.first(3),
          best_pairing: best_pairing,
          enrichment: item_enrichment(item),
        }
      end

      scored.sort_by { |s| -s[:score] }.first(limit)
    end

    private

    def similarity_score(profile_a, profile_b)
      tags_a = Set.new(profile_a.tags)
      tags_b = Set.new(profile_b.tags)

      # Jaccard similarity on tags
      union = (tags_a | tags_b).size
      return 0.0 if union.zero?
      tag_sim = (tags_a & tags_b).size.to_f / union

      # Structural similarity
      ma = profile_a.structure_metrics || {}
      mb = profile_b.structure_metrics || {}
      common_keys = ma.keys & mb.keys
      struct_sim = if common_keys.any?
                     diffs = common_keys.map { |k| (ma[k].to_f - mb[k].to_f).abs }
                     1.0 - (diffs.sum / common_keys.size)
                   else
                     0.5
                   end

      (tag_sim * 0.6 + struct_sim * 0.4).round(4)
    end

    def price_tier_compatible?(product_a, product_b, menu)
      price_a = avg_price_for_product(product_a, menu)
      price_b = avg_price_for_product(product_b, menu)
      return true if price_a.nil? || price_b.nil?

      ratio = [price_a, price_b].max / [price_a, price_b, 0.01].max
      ratio < 3.0
    end

    def avg_price_for_product(product, menu)
      items = product.menuitems
                     .joins(menusection: :menu)
                     .where(menus: { id: menu.id })
                     .where.not(price: nil)
      prices = items.pluck(:price).map(&:to_f).select(&:positive?)
      prices.any? ? (prices.sum / prices.size) : nil
    end

    def apply_diversity(sorted_candidates, source_product)
      return sorted_candidates.first(3) if sorted_candidates.size <= 3

      selected = []
      types_seen = Set.new

      sorted_candidates.each do |c|
        ctype = c[:candidate].product_type
        # Always take if we have fewer than 3 and haven't seen this type twice
        if selected.size < 3
          if types_seen.count(ctype).to_i < 2 || selected.size < 2
            selected << c
            types_seen << ctype
          end
        end
        break if selected.size >= 3
      end

      # Fill remaining slots if diversity filter was too strict
      if selected.size < 3
        sorted_candidates.each do |c|
          break if selected.size >= 3
          selected << c unless selected.include?(c)
        end
      end

      selected.first(3)
    end

    def preference_score(profile, smoky, taste, budget, menuitem)
      score = 0.0
      tags = Set.new(profile.tags)
      metrics = profile.structure_metrics || {}

      # Smoky preference
      if smoky
        score += 0.3 if tags.include?('smoke_peat') || metrics['peat_level'].to_f > 0.3
      else
        score -= 0.2 if tags.include?('smoke_peat') || metrics['peat_level'].to_f > 0.5
        score += 0.1 unless tags.include?('smoke_peat')
      end

      # Taste preference
      case taste
      when 'sweet'
        score += 0.3 if metrics['sweetness_level'].to_f > 0.4 || tags.include?('sweet')
        score += 0.1 if tags.include?('vanilla_oak') || tags.include?('caramel') || tags.include?('honey')
      when 'dry'
        score += 0.3 if metrics['sweetness_level'].to_f < 0.3
        score += 0.1 if tags.include?('citrus') || tags.include?('herbal')
      when 'spicy'
        score += 0.3 if tags.include?('spice')
        score += 0.1 if metrics['alcohol_intensity'].to_f > 0.5
      end

      # Budget preference
      price = menuitem.price.to_f
      if price > 0
        case budget
        when 1 then score += 0.2 if price <= 10
        when 2 then score += 0.2 if price > 8 && price <= 18
        when 3 then score += 0.2 if price > 15
        end
      end

      # Baseline: give every valid drink a small score
      score += 0.1

      score
    end

    # Wine-specific preference scoring — called from recommend_wines_for_guest
    def wine_preference_score(profile, wine_color_pref, body_pref, taste, budget, menuitem)
      score = 0.0
      tags = Set.new(profile.tags)
      metrics = profile.structure_metrics || {}
      parsed = menuitem.sommelier_parsed_fields.is_a?(Hash) ? menuitem.sommelier_parsed_fields : {}
      item_color = parsed['wine_color']

      # Wine color preference
      if wine_color_pref.present? && item_color.present?
        if wine_color_pref == item_color
          score += 0.35
        elsif wine_color_pref == 'no_preference'
          score += 0.1
        end
      else
        score += 0.1 # no color info, neutral
      end

      # Body preference
      body = metrics['body'].to_f
      case body_pref
      when 'light'
        score += 0.25 if body < 0.4
        score -= 0.1 if body > 0.6
      when 'medium'
        score += 0.25 if body >= 0.35 && body <= 0.65
      when 'full'
        score += 0.25 if body > 0.55
        score -= 0.1 if body < 0.35
      end

      # Taste preference (reuse same logic)
      case taste
      when 'sweet'
        score += 0.2 if metrics['sweetness_level'].to_f > 0.4 || tags.include?('sweet')
      when 'dry'
        score += 0.2 if metrics['sweetness_level'].to_f < 0.3
        score += 0.1 if metrics['acidity'].to_f > 0.5
      when 'fruity'
        score += 0.2 if tags.any? { |t| %w[berry stone_fruit tropical citrus].include?(t) }
      end

      # Budget preference
      price = menuitem.price.to_f
      if price > 0
        case budget
        when 1 then score += 0.15 if price <= 12
        when 2 then score += 0.15 if price > 10 && price <= 25
        when 3 then score += 0.15 if price > 20
        end
      end

      # Baseline
      score += 0.05
      score
    end

    def item_enrichment(menuitem)
      link = menuitem.menu_item_product_links.first
      return nil unless link

      product = link.product
      enrichment = product&.product_enrichments&.order(created_at: :desc)&.first
      return nil unless enrichment

      enrichment.payload_json.is_a?(Hash) ? enrichment.payload_json : nil
    end

    def build_rationale(product, candidate, score)
      shared = (Set.new(product.flavor_profile.tags) & Set.new(candidate.flavor_profile.tags)).to_a
      parts = []
      parts << "Similar flavor profile (#{(score * 100).round}% match)"
      parts << "Shared notes: #{shared.first(4).join(', ')}" if shared.any?
      parts.join('. ')
    end

    def save_recommendation(product, recommended, score, rationale)
      rec = SimilarProductRecommendation.find_or_initialize_by(
        product_id: product.id,
        recommended_product_id: recommended.id,
      )
      rec.assign_attributes(score: score, rationale: rationale)
      rec.save!
    rescue ActiveRecord::RecordNotUnique
      nil
    end
  end
end
