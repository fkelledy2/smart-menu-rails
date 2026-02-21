# frozen_string_literal: true

module BeverageIntelligence
  class WhiskeyParser
    # ── Whiskey Types ──────────────────────────────────────────────
    WHISKEY_TYPES = %w[
      single_malt blended_malt blended_scotch
      bourbon rye tennessee
      irish_single_malt irish_single_pot irish_blended
      japanese canadian
      single_grain other
    ].freeze

    TYPE_PATTERNS = {
      'single_malt'      => /\bsingle\s+malt\b/i,
      'blended_malt'     => /\bblended\s+malt\b/i,
      'blended_scotch'   => /\bblended\s+scotch\b/i,
      'bourbon'          => /\bbourbon\b/i,
      'rye'              => /\brye\s+whiske?y\b/i,
      'tennessee'        => /\btennessee\b/i,
      'irish_single_malt' => /\birish\s+single\s+malt\b/i,
      'irish_single_pot' => /\bsingle\s+pot\s+still\b/i,
      'irish_blended'    => /\birish\s+blend(?:ed)?\b/i,
      'japanese'         => /\bjapanese\b/i,
      'canadian'         => /\bcanadian\b/i,
      'single_grain'     => /\bsingle\s+grain\b/i,
    }.freeze

    # ── Regions ────────────────────────────────────────────────────
    WHISKEY_REGIONS = {
      'islay'          => 'Islay',
      'speyside'       => 'Speyside',
      'highland'       => 'Highland',
      'lowland'        => 'Lowland',
      'campbeltown'    => 'Campbeltown',
      'islands'        => 'Islands',
      'ireland'        => 'Ireland',
      'kentucky'       => 'Kentucky',
      'tennessee'      => 'Tennessee',
      'american_other' => 'American (Other)',
      'japan'          => 'Japan',
      'canada'         => 'Canada',
      'world'          => 'World',
    }.freeze

    # ── Cask Types ─────────────────────────────────────────────────
    CASK_TYPES = %w[
      bourbon_cask sherry_cask port_cask wine_cask rum_cask
      virgin_oak refill double_cask triple_cask other
    ].freeze

    CASK_PATTERNS = {
      'sherry_cask'  => /\b(sherry|oloroso|pedro\s+xim[ée]nez|px)\s*(cask|barrel|butt|finish|matured|aged)?\b/i,
      'bourbon_cask' => /\b(bourbon|american\s+oak)\s*(cask|barrel|finish|matured|aged)?\b/i,
      'port_cask'    => /\b(port|ruby|tawny)\s*(cask|pipe|finish|matured|aged)\b/i,
      'wine_cask'    => /\b(wine|red\s+wine|white\s+wine|burgundy|bordeaux|sauternes|madeira|marsala)\s*(cask|barrel|barrique|finish|matured|aged)\b/i,
      'rum_cask'     => /\brum\s*(cask|barrel|finish|matured|aged)\b/i,
      'virgin_oak'   => /\bvirgin\s+oak\b/i,
      'double_cask'  => /\bdouble\s*(cask|wood|matured)\b/i,
      'triple_cask'  => /\btriple\s*(cask|wood|matured)\b/i,
      'refill'       => /\brefill\b/i,
    }.freeze

    # ── Flavor Clusters (Wishart-derived, simplified) ──────────────
    FLAVOR_CLUSTERS = {
      'light_delicate' => { label: 'Light & Delicate',   wishart: %w[G H] },
      'fruity_sweet'   => { label: 'Fruity & Sweet',     wishart: %w[A B] },
      'rich_sherried'  => { label: 'Rich & Sherried',     wishart: %w[C E] },
      'spicy_dry'      => { label: 'Spicy & Dry',         wishart: %w[F] },
      'smoky_coastal'  => { label: 'Smoky & Coastal',     wishart: %w[I] },
      'heavily_peated' => { label: 'Heavily Peated',      wishart: %w[J] },
    }.freeze

    # ── Independent Bottlers ───────────────────────────────────────
    IB_NAMES = %w[
      gordon\ &\ macphail signatory cadenhead berry\ bros
      douglas\ laing hunter\ laing adelphi blackadder
      murray\ mcdavid compass\ box wemyss scotch\ malt\ whisky\ society
      smws that\ boutique-y chieftain's duncan\ taylor
    ].freeze

    AGE_REGEX = /\b(\d{1,2})\s*(?:yo|y\.o\.|years?\s*old|yr)\b/i
    BARE_AGE_REGEX = /\b(\d{1,2})\b/
    ABV_REGEX = /\b(\d{2,3}(?:[.,]\d{1,2})?)\s*%?\s*(?:abv|vol|alc)\b/i
    LIMITED_PATTERNS = /\b(limited\s+edition|special\s+release|cask\s+strength|single\s+cask|small\s+batch|hand\s+picked|distillery\s+exclusive|allocated)\b/i

    # ── Distillery Dictionary ──────────────────────────────────────
    # Maps distillery name → region key
    DISTILLERY_REGIONS = {
      # Islay
      'ardbeg'          => 'islay',
      'bowmore'         => 'islay',
      'bruichladdich'   => 'islay',
      'bunnahabhain'    => 'islay',
      'caol ila'        => 'islay',
      'kilchoman'       => 'islay',
      'lagavulin'       => 'islay',
      'laphroaig'       => 'islay',
      'port charlotte'  => 'islay',
      'octomore'        => 'islay',
      # Speyside
      'aberlour'        => 'speyside',
      'balvenie'        => 'speyside',
      'benriach'        => 'speyside',
      'cardhu'          => 'speyside',
      'cragganmore'     => 'speyside',
      'craigellachie'   => 'speyside',
      'dufftown'        => 'speyside',
      'glenfarclas'     => 'speyside',
      'glenfiddich'     => 'speyside',
      'glenlivet'       => 'speyside',
      'glen grant'      => 'speyside',
      'glen moray'      => 'speyside',
      'glenrothes'      => 'speyside',
      'glenallachie'    => 'speyside',
      'knockando'       => 'speyside',
      'macallan'        => 'speyside',
      'mortlach'        => 'speyside',
      'strathisla'      => 'speyside',
      'tamdhu'          => 'speyside',
      'tomintoul'       => 'speyside',
      # Highland
      'aberfeldy'       => 'highland',
      'ardmore'         => 'highland',
      'balblair'        => 'highland',
      'ben nevis'       => 'highland',
      'clynelish'       => 'highland',
      'dalmore'         => 'highland',
      'dalwhinnie'      => 'highland',
      'deanston'        => 'highland',
      'edradour'        => 'highland',
      'fettercairn'     => 'highland',
      'glen garioch'    => 'highland',
      'glengoyne'       => 'highland',
      'glenmorangie'    => 'highland',
      'oban'            => 'highland',
      'old pulteney'    => 'highland',
      'royal lochnagar' => 'highland',
      'tomatin'         => 'highland',
      'tullibardine'    => 'highland',
      # Lowland
      'auchentoshan'    => 'lowland',
      'bladnoch'        => 'lowland',
      'glenkinchie'     => 'lowland',
      'kingsbarns'      => 'lowland',
      # Campbeltown
      'glen scotia'     => 'campbeltown',
      'kilkerran'       => 'campbeltown',
      'springbank'      => 'campbeltown',
      # Islands
      'arran'           => 'islands',
      'highland park'   => 'islands',
      'jura'            => 'islands',
      'ledaig'          => 'islands',
      'scapa'           => 'islands',
      'talisker'        => 'islands',
      'tobermory'       => 'islands',
      # Irish
      'bushmills'       => 'ireland',
      'connemara'       => 'ireland',
      'cooley'          => 'ireland',
      'dingle'          => 'ireland',
      'green spot'      => 'ireland',
      'jameson'         => 'ireland',
      'kilbeggan'       => 'ireland',
      'midleton'        => 'ireland',
      'powers'          => 'ireland',
      'redbreast'       => 'ireland',
      'teeling'         => 'ireland',
      'tullamore'       => 'ireland',
      'tyrconnell'      => 'ireland',
      'yellow spot'     => 'ireland',
      'writers tears'   => 'ireland',
      "writer's tears"  => 'ireland',
      # Bourbon / American
      'baker\'s'        => 'kentucky',
      'basil hayden'    => 'kentucky',
      'blantons'        => 'kentucky',
      'blanton\'s'      => 'kentucky',
      'booker\'s'       => 'kentucky',
      'buffalo trace'   => 'kentucky',
      'bulleit'         => 'kentucky',
      'eagle rare'      => 'kentucky',
      'elijah craig'    => 'kentucky',
      'evan williams'   => 'kentucky',
      'four roses'      => 'kentucky',
      'heaven hill'     => 'kentucky',
      'jim beam'        => 'kentucky',
      'knob creek'      => 'kentucky',
      'maker\'s mark'   => 'kentucky',
      'makers mark'     => 'kentucky',
      'michter\'s'      => 'kentucky',
      'michters'        => 'kentucky',
      'old forester'    => 'kentucky',
      'old fitzgerald'  => 'kentucky',
      'pappy van winkle' => 'kentucky',
      'rabbit hole'     => 'kentucky',
      'russell\'s reserve' => 'kentucky',
      'wild turkey'     => 'kentucky',
      'weller'          => 'kentucky',
      'woodford reserve' => 'kentucky',
      'jack daniel\'s'  => 'tennessee',
      'jack daniels'    => 'tennessee',
      'george dickel'   => 'tennessee',
      'uncle nearest'   => 'tennessee',
      # Rye
      'rittenhouse'     => 'kentucky',
      'sazerac'         => 'kentucky',
      'whistlepig'      => 'american_other',
      'high west'       => 'american_other',
      'templeton'       => 'american_other',
      # Japanese
      'hakushu'         => 'japan',
      'hibiki'          => 'japan',
      'nikka'           => 'japan',
      'yamazaki'        => 'japan',
      'yoichi'          => 'japan',
      'miyagikyo'       => 'japan',
      'chichibu'        => 'japan',
      'mars shinshu'    => 'japan',
      'togouchi'        => 'japan',
      'akashi'          => 'japan',
      # Canadian
      'crown royal'     => 'canada',
      'lot 40'          => 'canada',
      'canadian club'   => 'canada',
      'pike creek'      => 'canada',
      'forty creek'     => 'canada',
    }.freeze

    # Sorted longest-first to ensure greedy matching
    DISTILLERY_NAMES_SORTED = DISTILLERY_REGIONS.keys.sort_by { |k| -k.length }.freeze

    # ── Public API ─────────────────────────────────────────────────

    def parse(menuitem)
      text = [
        menuitem.menusection&.name,
        menuitem.name,
        menuitem.description,
      ].compact_blank.join(' ')
      t = text.downcase

      fields = {}

      fields['distillery']     = detect_distillery(t)
      fields['whiskey_region'] = detect_region(t, fields['distillery'])
      fields['whiskey_type']   = detect_type(t, fields['whiskey_region'])
      fields['cask_type']      = detect_cask(t)
      fields['bottler']        = detect_bottler(t)
      fields['limited_edition'] = detect_limited(t)

      if (m = AGE_REGEX.match(t))
        fields['age_years'] = m[1].to_i
      elsif fields['distillery'].present?
        # Fallback: bare number after distillery name (e.g. "Macallan 18", "Yamazaki 12")
        distillery_lower = fields['distillery'].downcase
        after_distillery = t.split(distillery_lower, 2).last.to_s.strip
        if (m = BARE_AGE_REGEX.match(after_distillery))
          age = m[1].to_i
          fields['age_years'] = age if age >= 3 && age <= 50
        end
      end

      if (m = ABV_REGEX.match(t))
        fields['bottling_strength_abv'] = m[1].tr(',', '.').to_f
      elsif menuitem.respond_to?(:abv) && menuitem.abv.present?
        fields['bottling_strength_abv'] = menuitem.abv.to_f
      end

      confidence = compute_confidence(fields)
      [fields.compact_blank, confidence]
    end

    private

    def detect_distillery(text)
      DISTILLERY_NAMES_SORTED.each do |name|
        return name.split.map(&:capitalize).join(' ') if text.include?(name)
      end
      nil
    end

    def detect_region(text, distillery)
      # First: infer from distillery dictionary
      if distillery.present?
        key = DISTILLERY_REGIONS.keys.find { |k| k == distillery.downcase }
        return DISTILLERY_REGIONS[key] if key
      end

      # Second: explicit region keywords in text
      region_keywords = {
        'islay'       => /\bislay\b/i,
        'speyside'    => /\bspeyside\b/i,
        'highland'    => /\bhighland\b/i,
        'lowland'     => /\blowland\b/i,
        'campbeltown' => /\bcampbeltown\b/i,
        'islands'     => /\bislands?\b/i,
        'ireland'     => /\b(irish|ireland)\b/i,
        'kentucky'    => /\bkentucky\b/i,
        'tennessee'   => /\btennessee\b/i,
        'japan'       => /\bjapan(?:ese)?\b/i,
        'canada'      => /\bcanadian?\b/i,
      }

      region_keywords.each do |region, pattern|
        return region if text.match?(pattern)
      end

      nil
    end

    def detect_type(text, region)
      # Explicit type patterns first
      TYPE_PATTERNS.each do |type, pattern|
        return type if text.match?(pattern)
      end

      # Infer from region if no explicit match
      case region
      when 'kentucky'
        return 'bourbon' if text.match?(/\bbourbon\b/i) || !text.match?(/\brye\b/i)
      when 'tennessee'
        return 'tennessee'
      when 'ireland'
        return 'irish_blended' unless text.match?(/\bsingle\b/i)
      when 'japan'
        return 'japanese'
      when 'canada'
        return 'canadian'
      end

      nil
    end

    def detect_cask(text)
      CASK_PATTERNS.each do |cask, pattern|
        return cask if text.match?(pattern)
      end
      nil
    end

    def detect_bottler(text)
      IB_NAMES.each do |ib|
        return 'IB' if text.include?(ib)
      end
      text.match?(/\bbottled\s+by\b/i) ? 'IB' : 'OB'
    end

    def detect_limited(text)
      text.match?(LIMITED_PATTERNS) ? true : false
    end

    def compute_confidence(fields)
      score = 0.15 # baseline
      score += 0.25 if fields['distillery'].present?
      score += 0.15 if fields['whiskey_region'].present?
      score += 0.15 if fields['whiskey_type'].present?
      score += 0.10 if fields['cask_type'].present?
      score += 0.10 if fields['age_years'].present?
      score += 0.10 if fields['bottling_strength_abv'].present?
      [score, 1.0].min
    end
  end
end
