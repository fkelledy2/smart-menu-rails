# frozen_string_literal: true

module BeverageIntelligence
  class WineParser
    # Major grape varieties (red, white, rosé-capable)
    RED_GRAPES = %w[
      cabernet\ sauvignon merlot pinot\ noir syrah shiraz malbec tempranillo
      sangiovese nebbiolo grenache garnacha mourvèdre monastrell barbera
      primitivo zinfandel pinotage carmenere gamay petit\ verdot
      nero\ d'avola aglianico montepulciano corvina tannat touriga\ nacional
    ].freeze

    WHITE_GRAPES = %w[
      chardonnay sauvignon\ blanc riesling pinot\ grigio pinot\ gris
      gewürztraminer viognier chenin\ blanc semillon muscadet
      albariño verdejo grüner\ veltliner torrontés vermentino
      trebbiano garganega fiano greco cortese arneis pecorino
      marsanne roussanne müller-thurgau silvaner furmint
    ].freeze

    ROSE_GRAPES = %w[
      grenache garnacha cinsault mourvèdre syrah pinot\ noir tempranillo
    ].freeze

    ALL_GRAPES = (RED_GRAPES + WHITE_GRAPES + ROSE_GRAPES).uniq.freeze

    # Appellations / regions
    FRENCH_APPELLATIONS = %w[
      bordeaux bourgogne burgundy champagne alsace loire rhône rhone
      beaujolais languedoc provence côtes\ du\ rhône cotes\ du\ rhone
      saint-émilion saint-julien pauillac margaux médoc haut-médoc
      pomerol sauternes chablis meursault puligny-montrachet
      chassagne-montrachet gevrey-chambertin nuits-saint-georges
      côte\ de\ beaune côte\ de\ nuits pouilly-fuissé pouilly-fumé
      sancerre vouvray muscadet chinon côtes\ de\ provence
      châteauneuf-du-pape hermitage côte-rôtie gigondas
      crozes-hermitage condrieu minervois corbières
    ].freeze

    ITALIAN_APPELLATIONS = %w[
      chianti barolo barbaresco brunello\ di\ montalcino valpolicella
      amarone soave prosecco franciacorta asti lambrusco verdicchio
      montepulciano\ d'abruzzo primitivo\ di\ manduria nero\ d'avola
      etna sicilia toscana piemonte veneto trentino alto\ adige
      friuli collio bolgheri maremma montalcino langhe roero
      gavi gattinara ghemme lugana ribolla\ gialla
    ].freeze

    SPANISH_APPELLATIONS = %w[
      rioja ribera\ del\ duero priorat penedès rueda rías\ baixas
      rias\ baixas navarra jumilla toro cava jerez sherry
      valdepeñas la\ mancha somontano campo\ de\ borja
    ].freeze

    OTHER_APPELLATIONS = %w[
      napa\ valley sonoma willamette\ valley barossa\ valley
      margaret\ river marlborough hawke's\ bay stellenbosch
      mendoza mâcon douro vinho\ verde porto port
      mosel rheingau pfalz tokaj wachau kamptal
    ].freeze

    ALL_APPELLATIONS = (FRENCH_APPELLATIONS + ITALIAN_APPELLATIONS +
                        SPANISH_APPELLATIONS + OTHER_APPELLATIONS).freeze

    # Wine classifications
    CLASSIFICATIONS = {
      'docg'          => 'DOCG',
      'd.o.c.g.'      => 'DOCG',
      'doc'           => 'DOC',
      'd.o.c.'        => 'DOC',
      'dop'           => 'DOP',
      'igt'           => 'IGT',
      'aoc'           => 'AOC',
      'aop'           => 'AOP',
      'grand cru'     => 'Grand Cru',
      'premier cru'   => 'Premier Cru',
      '1er cru'       => 'Premier Cru',
      'gran reserva'  => 'Gran Reserva',
      'reserva'       => 'Reserva',
      'riserva'       => 'Riserva',
      'crianza'       => 'Crianza',
      'classico'      => 'Classico',
      'superiore'     => 'Superiore',
      'spätlese'      => 'Spätlese',
      'auslese'       => 'Auslese',
      'kabinett'      => 'Kabinett',
    }.freeze

    # Serve types
    SERVE_PATTERNS = {
      'glass'   => /\b(glass|bicchiere|verre|copa|glas)\b/i,
      'bottle'  => /\b(bottle|bottiglia|bouteille|botella|flasche|75\s*cl|750\s*ml)\b/i,
      'carafe'  => /\b(carafe|caraffa|jarra|half\s*bottle|37\.?5\s*cl|375\s*ml)\b/i,
      'magnum'  => /\b(magnum|1\.?5\s*l|150\s*cl)\b/i,
    }.freeze

    # Wine color detection
    COLOR_PATTERNS = {
      'red'       => /\b(red|rosso|rouge|tinto|rotwein)\b/i,
      'white'     => /\b(white|bianco|blanc|blanco|weißwein|weisswein)\b/i,
      'rosé'      => /\b(ros[ée]|rosato|rosado)\b/i,
      'sparkling' => /\b(sparkling|spumante|mousseux|espumoso|sekt|brut|prosecco|champagne|cava|crémant|franciacorta)\b/i,
      'dessert'   => /\b(dessert|sweet\s+wine|passito|vin\s+santo|moscato\s+d'asti|sauternes|tokaji|ice\s+wine|eiswein|late\s+harvest)\b/i,
      'fortified' => /\b(port|porto|sherry|jerez|madeira|marsala|vermouth)\b/i,
    }.freeze

    VINTAGE_REGEX = /\b(19[6-9]\d|20[0-2]\d)\b/

    # Parse wine-specific fields from a menuitem
    def parse(menuitem)
      text = [
        menuitem.menusection&.name,
        menuitem.name,
        menuitem.description,
      ].compact_blank.join(' ')
      t = text.downcase

      fields = {}

      fields['grape_variety'] = detect_grapes(t)
      fields['appellation']   = detect_appellation(t)
      fields['classification'] = detect_classification(t)
      fields['wine_color']    = detect_color(t, menuitem.menusection&.name.to_s)
      fields['serve_type']    = detect_serve_type(t)
      fields['producer']      = extract_producer(menuitem.name.to_s, fields)

      vintage = VINTAGE_REGEX.match(text)
      fields['vintage_year'] = vintage[1].to_i if vintage

      # Infer color from grape if not detected
      if fields['wine_color'].blank? && fields['grape_variety'].present?
        fields['wine_color'] = infer_color_from_grape(fields['grape_variety'].first)
      end

      confidence = compute_confidence(fields)

      [fields.compact_blank, confidence]
    end

    private

    def detect_grapes(text)
      found = ALL_GRAPES.select { |g| text.include?(g) }
      found.any? ? found.first(3) : nil
    end

    def detect_appellation(text)
      ALL_APPELLATIONS.find { |a| text.include?(a) }
    end

    def detect_classification(text)
      CLASSIFICATIONS.each do |pattern, label|
        return label if text.match?(/\b#{Regexp.escape(pattern)}\b/i)
      end
      nil
    end

    def detect_color(text, section_name)
      section_t = section_name.downcase

      # Check section name first (e.g. "Red Wines", "White Wines")
      COLOR_PATTERNS.each do |color, pattern|
        return color if section_t.match?(pattern)
      end

      # Then check item text
      COLOR_PATTERNS.each do |color, pattern|
        return color if text.match?(pattern)
      end

      nil
    end

    def detect_serve_type(text)
      SERVE_PATTERNS.each do |serve, pattern|
        return serve if text.match?(pattern)
      end
      nil
    end

    def extract_producer(name, fields)
      # Simple heuristic: if name contains a known grape or appellation,
      # the text before it is likely the producer
      tokens_to_strip = []
      tokens_to_strip += Array(fields['grape_variety'])
      tokens_to_strip << fields['appellation'] if fields['appellation']

      producer = name.dup
      tokens_to_strip.each do |token|
        producer = producer.gsub(/#{Regexp.escape(token)}/i, '').strip
      end

      # Remove vintage year
      producer = producer.gsub(VINTAGE_REGEX, '').strip

      # Remove trailing/leading punctuation
      producer = producer.gsub(/\A[\s,\-–]+|[\s,\-–]+\z/, '').strip

      producer.present? && producer.length > 2 ? producer : nil
    end

    def infer_color_from_grape(grape)
      return 'red'   if RED_GRAPES.include?(grape) && !WHITE_GRAPES.include?(grape)
      return 'white' if WHITE_GRAPES.include?(grape) && !RED_GRAPES.include?(grape)

      nil # ambiguous (e.g. pinot noir can be rosé or sparkling)
    end

    def compute_confidence(fields)
      score = 0.3 # baseline for being classified as wine
      score += 0.15 if fields['grape_variety'].present?
      score += 0.15 if fields['appellation'].present?
      score += 0.1  if fields['classification'].present?
      score += 0.1  if fields['wine_color'].present?
      score += 0.1  if fields['vintage_year'].present?
      score += 0.05 if fields['serve_type'].present?
      score += 0.05 if fields['producer'].present?
      [score, 1.0].min
    end
  end
end
