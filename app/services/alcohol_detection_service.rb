class AlcoholDetectionService
  KEYWORDS = {
    wine: %w[wine rosé rose chardonnay merlot cabernet sauvignon sauvignon blanc pinot noir pinot grigio riesling syrah malbec tempranillo rioja bordeaux chianti prosecco champagne cava],
    beer: %w[beer ale lager ipa pilsner pils pilsener stout porter weizen weiss wheat saison kolsch bitter tripel dubbel gueuze lambic helles dunkel],
    spirit: %w[spirit vodka gin rum tequila whisky whiskey bourbon scotch brandy cognac armagnac grappa pisco mezcal],
    liqueur: %w[liqueur amaro amaretto sambuca limoncello cointreau grand marnier baileys kahlua chartreuse campari aperol],
    cocktail: %w[cocktail martini negroni spritz margarita mojito old fashioned manhattan daiquiri sour mule paloma gimlet boulevardier cosmopolitan caipirinha sangria bellini],
    cider: ['cider', 'perry', 'hard seltzer'],
    sake: %w[sake nigori junmai ginjo daiginjo],
    mead: %w[mead hydromel],
  }.freeze

  NON_ALCOHOLIC_KEYWORDS = %w[
    coffee espresso cappuccino latte americano macchiato mocha
    tea chai matcha infusion tisane herbal
    juice jugo zumo succo saft smoothie
    cola coca-cola pepsi fanta sprite 7up dr pepper
    lemonade limonata limonade orangeade
    water acqua agua eau wasser sparkling still mineral tonic soda
    milkshake shake hot chocolate cocoa
  ].freeze

  NON_ALCOHOLIC_SECTIONS = [
    'soft drinks', 'soft drink', 'non alcoholic', 'non-alcoholic',
    'hot drinks', 'hot beverages', 'cold drinks', 'cold beverages',
    'juices', 'juice', 'smoothies', 'smoothie',
    'coffee', 'tea', 'teas', 'coffees',
    'waters', 'water', 'mineral water',
    'soft', 'boissons chaudes', 'boissons froides',
    'bevande analcoliche', 'refrescos', 'getränke alkoholfrei',
  ].freeze

  NEGATIONS = [
    'non alcoholic', 'non-alcoholic', 'alcohol free', 'alcohol-free', '0.0%', '0,0%', 'zero alcohol', 'senza alcol', 'analcolico', 'senza alcool', 'no alcohol', 'mocktail', 'virgin',
  ].freeze

  COOKING_MODIFIERS = %w[
    battered braised glazed infused marinated reduced sauce
    jus gravy cream risotto cake soaked flambé flambe
  ].freeze

  ABV_REGEX = /(\d+(?:[.,]\d+)?)\s*%/i

  SECTION_CLASS_MAP = {
    'wine' => 'wine', 'wines' => 'wine',
    'beer' => 'beer', 'beers' => 'beer',
    'spirits' => 'spirit', 'spirit' => 'spirit',
    'cocktails' => 'cocktail', 'cocktail' => 'cocktail',
    'liqueurs' => 'liqueur', 'liqueur' => 'liqueur',
    'bar' => 'cocktail',
    'cider' => 'cider', 'ciders' => 'cider',
    'sake' => 'sake',
    'mead' => 'mead',
  }.freeze

  def self.detect(section_name:, item_name:, item_description: nil)
    text = [section_name, item_name, item_description].compact.map { |s| normalize(s) }.join(' | ')
    item_text = [item_name, item_description].compact.map { |s| normalize(s) }.join(' ')
    section_norm = normalize(section_name)

    # 1. Negation short-circuit (explicit "non-alcoholic" / "mocktail" / "virgin" etc.)
    if NEGATIONS.any? { |n| text.include?(n) }
      return { decided: true, alcoholic: false, classification: 'non_alcoholic', abv: extract_abv(text), confidence: 0.9, note: 'negation match' }
    end

    # 2. Non-alcoholic section (e.g., "Soft Drinks", "Hot Drinks", "Juices", "Coffee & Tea")
    section_flat = section_norm.tr('_', ' ').gsub(%r{[-/&]}, ' ')
    if NON_ALCOHOLIC_SECTIONS.any? { |s| section_flat.include?(s) }
      return { decided: true, alcoholic: false, classification: 'non_alcoholic', abv: nil, confidence: 0.85, note: 'non-alcoholic section' }
    end

    # 3. ABV extraction — strong alcoholic signal
    abv = extract_abv(text)
    if abv
      sec_class = SECTION_CLASS_MAP[section_norm] || section_class_from_text(section_name)
      return { decided: true, alcoholic: true, classification: sec_class || 'other', abv: abv, confidence: 0.95, note: 'abv present' }
    end

    # 4. Determine section class
    sec_class = SECTION_CLASS_MAP[section_norm] || section_class_from_text(section_name)

    # 5. Non-alcoholic item keywords — check before section inference
    #    (e.g., "Water" listed under a "Wines" section should still be non-alcoholic)
    if NON_ALCOHOLIC_KEYWORDS.any? { |kw| word_match?(item_text, kw) }
      # Only if no alcoholic keywords also match the item
      has_alcoholic_kw = KEYWORDS.any? { |_, kws| kws.any? { |kw| word_match?(item_text, kw) } }
      unless has_alcoholic_kw
        return { decided: true, alcoholic: false, classification: 'non_alcoholic', abv: nil, confidence: 0.8, note: 'non-alcoholic keyword' }
      end
    end

    # 6. Section is a known alcoholic category — strong evidence on its own
    if sec_class
      return { decided: true, alcoholic: true, classification: sec_class, abv: nil, confidence: 0.75, note: 'section context' }
    end

    # 7. Keyword scoring on full text
    scores = Hash.new(0.0)
    KEYWORDS.each do |klass, kws|
      kws.each do |kw|
        scores[klass] += 0.2 if text.include?(kw)
      end
    end

    best_class, best_score = scores.max_by { |_, s| s } || [nil, 0.0]

    # 8. Strong signal: item name itself contains an alcoholic keyword
    #    But suppress if a cooking modifier is also present (e.g., "beer battered fish")
    item_name_norm = normalize(item_name)
    has_cooking_context = COOKING_MODIFIERS.any? { |mod| word_match?(item_text, mod) }
    if !has_cooking_context && best_class && best_score.to_f >= 0.2 && KEYWORDS[best_class].any? { |kw| word_match?(item_name_norm, kw) }
      return { decided: true, alcoholic: true, classification: best_class.to_s, abv: nil, confidence: 0.7, note: 'name keyword' }
    end

    # 9. Weaker combined evidence
    if best_score.to_f >= 0.4
      return { decided: true, alcoholic: true, classification: best_class.to_s, abv: nil, confidence: [best_score, 1.0].min, note: 'keyword match' }
    end

    # 10. Not enough evidence: undecided
    { decided: false, confidence: best_score.to_f }
  end

  def self.extract_abv(text)
    m = ABV_REGEX.match(text)
    return nil unless m

    raw = m[1].tr(',', '.')
    val = raw.to_f
    return nil if val <= 0.0 || val > 100.0

    val.round(1)
  end

  def self.normalize(s)
    s.to_s.downcase.strip
  end

  def self.word_match?(text, keyword)
    text.match?(/\b#{Regexp.escape(keyword)}\b/)
  end

  # Infer alcohol class from free-text section names like "Beer & Wine", "Bar / Cocktails", "Beverages"
  def self.section_class_from_text(section_name)
    text = normalize(section_name)
    return nil if text.blank?

    # Normalize common separators
    t = text.tr('_', ' ').gsub(%r{[-/&]}, ' ')

    # Direct token map
    SECTION_CLASS_MAP.each_key do |key|
      return SECTION_CLASS_MAP[key] if t.include?(key)
    end

    # Generic synonyms
    return 'cocktail' if t.include?('bar') # bar menus often cocktails/spirits
    return nil if t.include?('beverage') || t.include?('beverages') || t.include?('drinks') || t.include?('drink')

    # Multilingual hints
    return 'wine' if t.include?('vin') || t.include?('vino')
    return 'beer' if t.include?('bier') || t.include?('birra')

    # Keyword groups
    KEYWORDS.each do |klass, kws|
      kws.each do |kw|
        return klass.to_s if t.include?(kw)
      end
    end

    nil
  end
end
