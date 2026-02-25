require 'nokogiri'

module MenuDiscovery
  class WebsiteMenuFinder
    DEFAULT_MAX_PAGES = 20

    # Multilingual menu-related keywords for URL path matching.
    # Scored in two tiers: strong (very likely menu) and weak (possibly menu).
    STRONG_PATH_KEYWORDS = %w[
      menu menus food-menu food_menu drink-menu drink_menu
      carte la-carte speisekarte getranke
      menu_food menu_drink menu_bar
    ].freeze

    WEAK_PATH_KEYWORDS = %w[
      food drink drinks brunch lunch dinner breakfast
      cocktail cocktails wine wines beer beers
      bistrot bistro brasserie trattoria osteria caffetteria
      bar-menu pub-menu kitchen dessert desserts
      starters mains sides tapas antipasti primi secondi
      kaart menukaart dranken eten
      carta bebidas comidas almuerzo cena
      pranzo cena colazione aperitivo digestivo
    ].freeze

    # Paths that should never be classified as menu pages, regardless of content.
    NON_MENU_PATH_PATTERN = %r{/(about|contact|blog|news|press|careers|jobs|faq|team|gallery|events|booking|reserv|privacy|cookie|terms|legal|imprint|impressum|login|signup|register|cart|checkout|shop|store|account|search|sitemap|404|500)([/-]|$)}i

    # Common language path prefixes used by multilingual sites.
    LANGUAGE_PREFIX_PATTERN = %r{\A/(en|it|de|fr|es|nl|pt|cs|pl|ru|ja|zh|ko|ar|tr|sv|da|fi|no|el|hu|ro|bg|hr|sk|sl|uk|ca|eu|gl|et|lv|lt)(/.*)}i

    # Link text patterns that strongly suggest menu navigation.
    MENU_LINK_TEXT_PATTERNS = /
      \b(menu|menus|food\s*(&|and)?\s*drink|our\s+menu|see\s+menu|view\s+menu|
      speisekarte|getränke|carte|la\s+carte|
      lunch|brunch|dinner|breakfast|
      cocktail|wine\s*(list|menu|card)|drink\s*(list|menu)|beer\s*(list|menu)|
      bistrot?|kitchen|cucina|caffetteria|bar\s+menu|
      starters|mains|desserts|tapas|
      pranzo|cena|colazione|aperitivo|
      carta|bebidas|comidas)\b
    /xi

    def initialize(base_url:, http_client: HTTParty, robots_checker: nil)
      @base_url = normalize_url(base_url)
      @http_client = http_client
      @robots_checker = robots_checker || RobotsTxtChecker.new(http_client: http_client)

      raise ArgumentError, 'base_url required' if @base_url.blank?
    end

    # Returns only PDF URLs (backward compatible)
    def find_menu_pdfs(max_pages: DEFAULT_MAX_PAGES)
      result = find_menus(max_pages: max_pages)
      result[:pdfs]
    end

    # Returns { pdfs: [String], html_menu_pages: [{ url: String, html: String }] }
    #
    # Strategy:
    #   1. Crawl homepage → extract ALL same-host links with scores
    #   2. Visit pages in priority order (highest-scored first)
    #   3. From each visited page, discover further links (also scored)
    #   4. Classify visited pages as menu pages using URL + content heuristics
    #   5. GPT fallback: if heuristics find nothing, ask GPT to pick menu URLs
    def find_menus(max_pages: DEFAULT_MAX_PAGES)
      max = [max_pages.to_i, 1].max
      max = DEFAULT_MAX_PAGES if max_pages.to_i <= 0

      base_uri = URI.parse(@base_url)
      @host = base_uri.host

      visited = Set.new
      # Priority queue: [[score, url, depth]]
      pq = ScoredQueue.new
      pq.push(100, normalize_crawl_url(@base_url), 0) # homepage always first

      discovered_pdfs = Set.new
      html_menu_pages = []
      # Track all discovered links for GPT fallback
      @all_discovered_links = []

      while pq.any? && visited.size < max
        _score, url, depth = pq.pop
        next if visited.include?(url)
        next unless @robots_checker.allowed?(url)

        visited << url

        html = fetch_html(url)
        next if html.blank?

        doc = Nokogiri::HTML(html)
        next if noindex?(doc: doc)

        # Evaluate this page for menu content (skip known non-menu paths)
        url_score = score_url(url)
        is_excluded = excluded_path?(url)
        if !is_excluded && url_score.positive? && page_has_menu_content?(doc)
          html_menu_pages << { url: url, html: html }
        elsif !is_excluded && depth.positive? && url_score.zero? && page_has_strong_menu_content?(doc)
          # No URL signal but very strong content — include with higher bar
          html_menu_pages << { url: url, html: html }
        end

        # Extract links with text for scoring
        doc.css('a[href]').each do |anchor|
          href = anchor['href'].to_s.strip
          next if href.blank?

          abs = absolutize(base_uri: base_uri, href: href)
          next if abs.nil?
          next unless abs.host == @host
          next if abs.fragment.present? && abs.path == base_uri.path # skip #anchors on same page

          link_url = normalize_crawl_url(abs.to_s)
          next if visited.include?(link_url)

          link_text = anchor.text.to_s.strip.gsub(/\s+/, ' ')

          if abs.path.to_s.downcase.end_with?('.pdf')
            discovered_pdfs << link_url
            next
          end

          link_score = score_link(uri: abs, link_text: link_text)
          @all_discovered_links << { url: link_url, text: link_text, score: link_score }

          # From homepage (depth 0): queue ALL internal links (broader discovery)
          # From deeper pages: only queue if the link scores > 0
          if depth.zero? || link_score.positive?
            pq.push(link_score, link_url, depth + 1)
          end
        end
      end

      # GPT fallback: if heuristics found no menu pages, ask GPT
      if html_menu_pages.empty? && @all_discovered_links.any?
        gpt_urls = gpt_identify_menu_pages(@all_discovered_links, visited)
        gpt_urls.each do |gpt_url|
          next if visited.include?(gpt_url)

          html = fetch_html(gpt_url)
          next if html.blank?

          html_menu_pages << { url: gpt_url, html: html }
        end
      end

      # Deduplicate language variants: prefer pages matching the base URL's language prefix
      html_menu_pages = deduplicate_language_variants(html_menu_pages, base_uri)

      { pdfs: discovered_pdfs.to_a, html_menu_pages: html_menu_pages }
    end

    private

    # Score a URL path for menu relevance (0 = no signal, higher = more likely)
    def score_url(url)
      path = URI.parse(url).path.to_s.downcase
      score = 0

      STRONG_PATH_KEYWORDS.each { |kw| score += 10 if path.include?(kw) }
      WEAK_PATH_KEYWORDS.each { |kw| score += 3 if path.include?(kw) }

      # Penalize common non-menu paths
      score -= 20 if path.match?(%r{/(blog|news|press|careers|jobs|contact|about|faq|team|gallery|events|booking|reserv|privacy|cookie|terms|legal|imprint|impressum)(/|$)})

      [score, 0].max
    rescue URI::InvalidURIError
      0
    end

    # Score a link by combining URL path keywords + anchor text signals
    def score_link(uri:, link_text:)
      score = score_url(uri.to_s)

      # Score link text
      text = link_text.downcase
      if text.match?(MENU_LINK_TEXT_PATTERNS)
        score += 15
      end

      # Bonus for short, navigation-like link text (likely nav items)
      if text.length.between?(2, 30) && text.match?(/\A[a-z\s&\-'éèêëàáâãòóôõùúûüìíîïñç]+\z/i)
        score += 2
      end

      score
    end

    # Is this URL a known non-menu path or the homepage?
    def excluded_path?(url)
      uri = URI.parse(url)
      path = uri.path.to_s.downcase

      # Homepage is never a menu page
      return true if path.blank? || path == '/' || path == ''

      # Known non-menu paths
      return true if path.match?(NON_MENU_PATH_PATTERN)

      false
    rescue URI::InvalidURIError
      false
    end

    # Heuristic: does this HTML page contain content that looks like a menu?
    # Looks for price-like strings, multiple list items, structured sections.
    def page_has_menu_content?(doc)
      text = doc.text.to_s

      # Count price-like patterns: €12.50, $9, £15, 12,50€, Kč, etc.
      price_count = text.scan(/[€$£]\s?\d+[.,]?\d{0,2}|\d+[.,]\d{2}\s?[€$£Kč]|\d+\s?(?:EUR|USD|GBP|CZK)\b/i).length
      return true if price_count >= 3

      # Check for structured menu-like elements
      menu_sections = doc.css('h2, h3, h4, .menu-section, .menu-category, [class*="menu"]').length
      list_items = doc.css('li, .menu-item, .dish, [class*="item"], [class*="dish"], [class*="price"], [class*="piatto"], [class*="plat"]').length
      return true if menu_sections >= 2 && list_items >= 5

      # Check for description + price patterns in text (item name ... price)
      item_price_lines = text.lines.count { |l| l.strip.match?(/\S.{5,}\s+\d+[.,]?\d{0,2}\s*$/) }
      return true if item_price_lines >= 4

      false
    end

    # Stricter content check for pages that have no URL signal at all.
    # Requires more evidence before classifying as a menu page.
    def page_has_strong_menu_content?(doc)
      text = doc.text.to_s

      price_count = text.scan(/[€$£]\s?\d+[.,]?\d{0,2}|\d+[.,]\d{2}\s?[€$£Kč]|\d+\s?(?:EUR|USD|GBP|CZK)\b/i).length
      return true if price_count >= 8

      menu_sections = doc.css('h2, h3, h4, .menu-section, .menu-category, [class*="menu"]').length
      list_items = doc.css('li, .menu-item, .dish, [class*="item"], [class*="dish"], [class*="price"], [class*="piatto"], [class*="plat"]').length
      return true if menu_sections >= 3 && list_items >= 10

      false
    end

    # Deduplicate pages that exist in multiple language variants.
    # E.g., /food and /en/food are the same content — keep only the preferred one.
    # Preference: if the base URL has a language prefix (e.g., /en/), prefer /en/* pages.
    # Otherwise, prefer the root (no prefix) version.
    def deduplicate_language_variants(pages, base_uri)
      return pages if pages.size <= 1

      base_path = base_uri.path.to_s.downcase
      preferred_lang = base_path.match(LANGUAGE_PREFIX_PATTERN)&.[](1)

      # Group pages by their "canonical" path (stripped of language prefix)
      grouped = {}
      pages.each do |page|
        uri = begin
          URI.parse(page[:url])
        rescue StandardError
          next
        end
        path = uri.path.to_s.downcase

        lang_match = path.match(LANGUAGE_PREFIX_PATTERN)
        canonical = lang_match ? lang_match[2] : path
        canonical = canonical.chomp('/')
        canonical = '/' if canonical.blank?

        grouped[canonical] ||= []
        grouped[canonical] << { page: page, lang: lang_match&.[](1) }
      end

      # For each group, pick the preferred variant
      grouped.flat_map do |_canonical, variants|
        if variants.size == 1
          variants.map { |v| v[:page] }
        else
          # Prefer variant matching the base URL's language
          preferred = if preferred_lang
                        variants.find { |v| v[:lang] == preferred_lang }
                      else
                        variants.find { |v| v[:lang].nil? }
                      end
          preferred ||= variants.first
          [preferred[:page]]
        end
      end
    end

    # GPT fallback: send the site's link map and ask which are menu pages
    def gpt_identify_menu_pages(links, visited)
      return [] unless defined?(HTTParty)

      # Deduplicate and pick top candidates
      candidates = links
        .uniq { |l| l[:url] }
        .reject { |l| visited.include?(l[:url]) }
        .reject { |l| l[:url].match?(%r{/(privacy|cookie|terms|legal|imprint)}) }
        .sort_by { |l| -l[:score] }
        .first(40)

      return [] if candidates.empty?

      link_list = candidates.map { |l| "#{l[:text].presence || '(no text)'} → #{l[:url]}" }.join("\n")

      prompt = <<~PROMPT
        You are analyzing the navigation links of a restaurant website.
        Below is a list of internal links found on the site.
        Your task: identify which URLs are likely MENU pages (food menu, drink menu, wine list, cocktail menu, brunch menu, etc.)

        Links:
        #{link_list}

        Return ONLY a JSON array of the URLs that are menu pages.
        Example: ["https://example.com/food-menu", "https://example.com/drinks"]
        If none look like menu pages, return: []
        Output ONLY valid JSON. No commentary.
      PROMPT

      api_key = Rails.application.credentials.dig(:openai, :api_key) || ENV.fetch('OPENAI_API_KEY', nil)
      return [] if api_key.blank?

      response = HTTParty.post(
        'https://api.openai.com/v1/chat/completions',
        headers: {
          'Authorization' => "Bearer #{api_key}",
          'Content-Type' => 'application/json',
        },
        body: {
          model: 'gpt-4o-mini',
          messages: [{ role: 'user', content: prompt }],
          temperature: 0,
          max_tokens: 500,
        }.to_json,
        timeout: 30,
      )

      content = response.parsed_response.dig('choices', 0, 'message', 'content').to_s.strip
      content = content.sub(/^```\w*\s*/m, '').sub(/```\s*\z/m, '').strip if content.start_with?('```')

      urls = JSON.parse(content)
      return [] unless urls.is_a?(Array)

      urls.select { |u| u.is_a?(String) && u.start_with?('http') }
    rescue StandardError => e
      Rails.logger.warn "WebsiteMenuFinder GPT fallback failed: #{e.message}"
      []
    end

    # Normalize a URL for deduplication: strip trailing slash (except root), fragment
    def normalize_crawl_url(url)
      uri = URI.parse(url)
      uri.fragment = nil
      path = uri.path.to_s
      uri.path = path.chomp('/') if path.length > 1
      uri.to_s
    rescue URI::InvalidURIError
      url
    end

    def normalize_url(url)
      u = url.to_s.strip
      return nil if u.blank?

      uri = URI.parse(u)
      uri.scheme = 'https' if uri.scheme.blank?
      uri.to_s
    rescue URI::InvalidURIError
      nil
    end

    def fetch_html(url)
      resp = @http_client.get(url, headers: {
        'User-Agent' => 'SmartMenuBot/1.0 (+https://www.mellow.menu)',
        'Accept' => 'text/html,application/xhtml+xml',
      }, timeout: 20,)

      return nil unless resp.respond_to?(:code)
      return nil unless resp.code.to_i >= 200 && resp.code.to_i < 300

      content_type = resp.headers['content-type'].to_s
      return nil unless content_type.include?('text/html') || content_type == ''

      resp.body.to_s
    rescue StandardError
      nil
    end

    def absolutize(base_uri:, href:)
      return nil if href.blank?
      return nil if href.start_with?('mailto:', 'tel:', 'javascript:')

      URI.join(base_uri.to_s, href)
    rescue URI::InvalidURIError
      nil
    end

    def noindex?(doc:)
      robots = doc.at_css('meta[name="robots"]')&.[]('content').to_s.downcase
      return true if robots.include?('noindex') || robots.include?('nosnippet')

      false
    end

    # Simple priority queue for crawl ordering
    class ScoredQueue
      def initialize
        @items = []
      end

      def push(score, url, depth)
        @items << [score, url, depth]
        @items.sort_by! { |s, _, _| -s } # highest score first
      end

      def pop
        @items.shift
      end

      delegate :any?, to: :@items
    end
  end
end
