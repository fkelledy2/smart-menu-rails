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

  NEGATIONS = [
    'non alcoholic', 'non-alcoholic', 'alcohol free', 'alcohol-free', '0.0%', '0,0%', 'zero alcohol', 'senza alcol', 'analcolico', 'senza alcool', 'no alcohol', 'mocktail', 'virgin',
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

    # Negation short-circuit
    if NEGATIONS.any? { |n| text.include?(n) }
      return { decided: true, alcoholic: false, classification: 'non_alcoholic', abv: extract_abv(text), confidence: 0.9, note: 'negation match' }
    end

    # ABV extraction as signal
    abv = extract_abv(text)
    if abv
      sec_class = SECTION_CLASS_MAP[normalize(section_name)] || section_class_from_text(section_name)
      return { decided: true, alcoholic: true, classification: sec_class || 'other', abv: abv, confidence: 0.95, note: 'abv present' }
    end

    # Section hint
    sec_class = SECTION_CLASS_MAP[normalize(section_name)] || section_class_from_text(section_name)
    sec_score = sec_class ? 0.4 : 0.0

    # Keyword scoring
    scores = Hash.new(0.0)
    KEYWORDS.each do |klass, kws|
      kws.each do |kw|
        if text.include?(kw)
          scores[klass] += 0.2
        end
      end
    end

    # Pick best class
    best_class, best_score = scores.max_by { |_, s| s } || [nil, 0.0]

    # Strong signal: item name itself contains a class keyword (e.g., 'pils', 'ipa', 'stout')
    item_name_norm = normalize(item_name)
    if best_class && best_score.to_f >= 0.2 && KEYWORDS[best_class].any? { |kw| item_name_norm.include?(kw) }
      classification = best_class.to_s
      return { decided: true, alcoholic: true, classification: classification, abv: abv, confidence: 0.6, note: 'name keyword' }
    end

    # Combine evidence
    alcoholic_score = 0.0
    alcoholic_score += 0.4 if abv
    alcoholic_score += 0.3 if best_score.to_f >= 0.2
    alcoholic_score += sec_score

    if alcoholic_score >= 0.5
      classification = best_class&.to_s || sec_class || 'other'
      return { decided: true, alcoholic: true, classification: classification, abv: abv, confidence: [alcoholic_score, 1.0].min, note: 'rule match' }
    end

    # Not enough evidence: undecided
    { decided: false, confidence: alcoholic_score }
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
