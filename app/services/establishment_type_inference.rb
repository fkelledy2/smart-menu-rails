class EstablishmentTypeInference
  ALLOWED = %w[restaurant bar wine_bar whiskey_bar].freeze

  LABELS = {
    'restaurant' => 'Restaurant',
    'bar' => 'Bar',
    'wine_bar' => 'Wine bar',
    'whiskey_bar' => 'Whiskey bar',
  }.freeze

  def infer_from_google_places_types(types)
    raw = Array(types).map { |t| t.to_s.strip.downcase }.compact_blank

    inferred = []
    inferred << 'whiskey_bar' if raw.include?('whiskey_bar')
    inferred << 'wine_bar' if raw.include?('wine_bar')

    if raw.include?('bar') || raw.include?('night_club')
      inferred << 'bar'
    end

    if raw.include?('restaurant') || raw.include?('food')
      inferred << 'restaurant'
    end

    inferred.uniq & ALLOWED
  end

  def infer_from_text(text)
    t = text.to_s.downcase
    return [] if t.blank?

    inferred = []
    inferred << 'whiskey_bar' if t.include?('whiskey')
    inferred << 'wine_bar' if t.include?('wine')

    inferred << 'bar' if t.match?(/\bbar\b/)
    inferred << 'restaurant' if t.include?('restaurant')

    inferred.uniq & ALLOWED
  end

  def labels_for(establishment_types)
    types = Array(establishment_types).map(&:to_s)
    types.filter_map { |t| LABELS[t] }
  end
end
