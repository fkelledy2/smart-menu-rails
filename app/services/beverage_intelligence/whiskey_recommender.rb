# frozen_string_literal: true

module BeverageIntelligence
  class WhiskeyRecommender
    CLUSTERS = WhiskeyParser::FLAVOR_CLUSTERS
    REGIONS  = WhiskeyParser::WHISKEY_REGIONS

    NEIGHBORING_CLUSTERS = {
      'light_delicate' => %w[fruity_sweet spicy_dry],
      'fruity_sweet'   => %w[light_delicate rich_sherried],
      'rich_sherried'  => %w[fruity_sweet spicy_dry],
      'spicy_dry'      => %w[light_delicate rich_sherried smoky_coastal],
      'smoky_coastal'  => %w[spicy_dry heavily_peated],
      'heavily_peated' => %w[smoky_coastal],
    }.freeze

    REGION_GROUPS = {
      'scotch'      => %w[islay speyside highland lowland campbeltown islands],
      'bourbon_rye' => %w[kentucky tennessee american_other],
      'irish'       => %w[ireland],
      'japanese'    => %w[japan],
    }.freeze

    # ── Quick Pick Mode ────────────────────────────────────────────

    def recommend_for_guest(menu:, preferences:, limit: 3, exclude_ids: [])
      experience   = preferences[:experience_level]  # newcomer, casual, enthusiast
      region_pref  = preferences[:region_pref]        # scotch, bourbon_rye, irish, japanese, surprise_me
      flavor_pref  = preferences[:flavor_pref]        # cluster key
      budget       = preferences[:budget]             # 1, 2, 3

      items = whiskey_items(menu)

      scored = items.filter_map do |item|
        parsed = parsed_fields(item)
        next if parsed.empty?

        score = whiskey_preference_score(parsed, experience, region_pref, flavor_pref, budget, item)

        # Deprioritize already-shown items (session memory)
        score -= 0.15 if exclude_ids.include?(item.id)

        next if score <= 0

        why = build_why_text(parsed, experience, region_pref, flavor_pref, item)

        {
          menuitem: item,
          score: score.round(4),
          tags: extract_tags(parsed, item),
          why_text: why,
          parsed_fields: parsed,
          new_arrival: item.created_at >= 14.days.ago,
          rare: parsed['limited_edition'] == true,
        }
      end

      scored.sort_by { |s| -s[:score] }.first(limit)
    end

    # ── Explore Mode ───────────────────────────────────────────────

    def explore(menu:, cluster: nil, region: nil, age_range: nil, price_range: nil, new_only: false, rare_only: false)
      items = whiskey_items(menu)

      # Build quadrant counts (before filtering)
      quadrants = build_quadrants(items)

      # Apply filters
      filtered = items.select do |item|
        parsed = parsed_fields(item)
        next false if parsed.empty?

        item_cluster = parsed['staff_flavor_cluster'] || infer_cluster(parsed, item)

        pass = true
        pass = false if cluster.present? && item_cluster != cluster
        pass = false if region.present? && parsed['whiskey_region'] != region
        pass = false if age_range.present? && !age_in_range?(parsed['age_years'], age_range)
        pass = false if price_range.present? && !price_in_range?(item.price, price_range)
        pass = false if new_only && item.created_at < 14.days.ago
        pass = false if rare_only && parsed['limited_edition'] != true
        pass
      end

      explore_items = filtered.map do |item|
        parsed = parsed_fields(item)
        {
          menuitem: item,
          parsed_fields: parsed,
          cluster: parsed['staff_flavor_cluster'] || infer_cluster(parsed, item),
          tags: extract_tags(parsed, item),
          new_arrival: item.created_at >= 14.days.ago,
          rare: parsed['limited_edition'] == true,
        }
      end

      { quadrants: quadrants, items: explore_items }
    end

    private

    def whiskey_items(menu)
      menu.menuitems
          .joins(:menusection)
          .where('menusections.archived IS NOT TRUE')
          .where(itemtype: :whiskey, status: 'active')
    end

    def parsed_fields(item)
      pf = item.sommelier_parsed_fields
      pf.is_a?(Hash) ? pf : {}
    end

    def whiskey_preference_score(parsed, experience, region_pref, flavor_pref, budget, item)
      score = 0.0

      # Region match (0.25 weight)
      item_region = parsed['whiskey_region']
      if region_pref == 'surprise_me'
        score += 0.15
      elsif item_region.present? && region_matches?(item_region, region_pref)
        score += 0.25
      end

      # Flavor cluster match (0.30 weight)
      cluster = parsed['staff_flavor_cluster'] || infer_cluster(parsed, item)
      if cluster.present? && flavor_pref.present?
        if cluster == flavor_pref
          score += 0.30
        elsif NEIGHBORING_CLUSTERS[flavor_pref]&.include?(cluster)
          score += 0.15
        end
      end

      # Experience-level adjustment (0.15 weight)
      age = parsed['age_years'].to_i
      abv = parsed['bottling_strength_abv'].to_f
      case experience
      when 'newcomer'
        score += 0.15 if abv <= 43 || abv.zero?
        score -= 0.1 if abv > 50
        score += 0.05 if %w[light_delicate fruity_sweet].include?(cluster)
      when 'casual'
        score += 0.10
      when 'enthusiast'
        score += 0.15 if age >= 12 || abv > 46
        score += 0.05 if parsed['limited_edition'] == true
      end

      # Budget preference (0.20 weight)
      price = item.price.to_f
      if price > 0
        case budget.to_i
        when 1 then score += 0.20 if price <= 12
        when 2 then score += 0.20 if price > 10 && price <= 20
        when 3 then score += 0.20 if price > 18
        end
      end

      # Staff pick bonus
      score += 0.05 if parsed['staff_pick'] == true

      # Baseline
      score += 0.05
      score
    end

    def region_matches?(item_region, pref)
      return false if item_region.blank? || pref.blank?

      group = REGION_GROUPS[pref]
      return group.include?(item_region) if group

      item_region == pref
    end

    def infer_cluster(parsed, item)
      # Heuristic cluster inference from available data
      region = parsed['whiskey_region']
      cask = parsed['cask_type']
      wtype = parsed['whiskey_type']

      return 'heavily_peated' if region == 'islay'
      return 'smoky_coastal' if region == 'islands'
      return 'rich_sherried' if cask&.include?('sherry')
      return 'fruity_sweet' if %w[bourbon tennessee].include?(wtype)
      return 'light_delicate' if region == 'lowland'
      return 'spicy_dry' if wtype == 'rye'

      nil
    end

    def build_quadrants(items)
      counts = Hash.new(0)
      items.each do |item|
        parsed = parsed_fields(item)
        cluster = parsed['staff_flavor_cluster'] || infer_cluster(parsed, item)
        counts[cluster] += 1 if cluster.present?
      end

      CLUSTERS.to_h do |key, cfg|
        [key, { label: cfg[:label], count: counts[key] }]
      end
    end

    def age_in_range?(age, range)
      return false if age.nil? || age.zero?

      case range.to_s
      when 'young'    then age <= 10
      when 'mid'      then age > 10 && age <= 18
      when 'mature'   then age > 18
      else true
      end
    end

    def price_in_range?(price, range)
      p = price.to_f
      return false if p <= 0

      case range.to_s
      when 'value'   then p <= 12
      when 'mid'     then p > 10 && p <= 20
      when 'premium' then p > 18
      else true
      end
    end

    def extract_tags(parsed, item)
      tags = []
      tags << 'smoke_peat' if %w[heavily_peated smoky_coastal].include?(parsed['staff_flavor_cluster'] || infer_cluster(parsed, item))
      tags << 'sweet' if %w[fruity_sweet rich_sherried].include?(parsed['staff_flavor_cluster'] || infer_cluster(parsed, item))
      tags << 'vanilla_oak' if parsed['cask_type']&.include?('bourbon')
      tags << 'dried_fruit' if parsed['cask_type']&.include?('sherry')
      tags << 'spice' if parsed['whiskey_type'] == 'rye'

      profile = item.respond_to?(:flavor_profile) ? item.flavor_profile : nil
      if profile&.tags&.any?
        tags = (profile.tags.first(3) + tags).uniq
      end

      tags.first(5)
    end

    def build_why_text(parsed, experience, region_pref, flavor_pref, item)
      parts = []

      if parsed['distillery'].present?
        parts << "From #{parsed['distillery']}"
        parts << "in #{REGIONS[parsed['whiskey_region']]}" if parsed['whiskey_region'].present?
      end

      if parsed['age_years'].present? && parsed['age_years'] > 0
        parts << "aged #{parsed['age_years']} years"
      end

      if parsed['cask_type'].present?
        parts << "matured in #{parsed['cask_type'].tr('_', ' ')}"
      end

      case experience
      when 'newcomer'
        parts << "— a great starting point" if parsed.fetch('bottling_strength_abv', 43).to_f <= 43
      when 'enthusiast'
        parts << "— #{parsed['bottling_strength_abv']}% ABV" if parsed['bottling_strength_abv'].to_f > 46
      end

      parts.compact_blank.join(', ').presence || "A fine choice from the collection"
    end
  end
end
