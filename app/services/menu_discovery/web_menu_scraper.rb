require 'nokogiri'

module MenuDiscovery
  # Extracts clean, structured text from HTML menu pages suitable for GPT parsing.
  # Bypasses the PDF pipeline entirely — HTML → clean text → GPT → OcrMenuImport.
  class WebMenuScraper
    def initialize(http_client: HTTParty, robots_checker: nil)
      @http_client = http_client
      @robots_checker = robots_checker || RobotsTxtChecker.new(http_client: http_client)
    end

    # Accept pre-fetched pages from WebsiteMenuFinder or fetch fresh from URLs.
    # pages: array of { url: String, html: String } or just URLs as strings.
    # Returns: { menu_text: String, pages_scraped: Integer, source_urls: [String] }
    def scrape(pages)
      pages = Array(pages)
      return empty_result if pages.empty?

      all_text = []
      source_urls = []

      pages.each do |page|
        url, html = if page.is_a?(Hash)
                      [page[:url] || page['url'], page[:html] || page['html']]
                    else
                      [page.to_s, nil]
                    end

        next if url.blank?

        html = fetch_html(url) if html.blank?
        next if html.blank?

        doc = Nokogiri::HTML(html)
        text = extract_menu_text(doc, url)
        next if text.blank?

        source_urls << url
        all_text << "--- Menu page: #{url} ---\n#{text}"
      end

      return empty_result if all_text.empty?

      {
        menu_text: all_text.join("\n\n"),
        pages_scraped: source_urls.size,
        source_urls: source_urls,
      }
    end

    private

    def empty_result
      { menu_text: '', pages_scraped: 0, source_urls: [] }
    end

    def fetch_html(url)
      return nil unless @robots_checker.allowed?(url)

      resp = @http_client.get(url, headers: {
        'User-Agent' => 'SmartMenuBot/1.0 (+https://www.mellow.menu)',
        'Accept' => 'text/html,application/xhtml+xml',
      }, timeout: 20)

      return nil unless resp.respond_to?(:code)
      return nil unless resp.code.to_i >= 200 && resp.code.to_i < 300

      content_type = resp.headers['content-type'].to_s
      return nil unless content_type.include?('text/html') || content_type == ''

      resp.body.to_s
    rescue StandardError
      nil
    end

    # Extract clean menu text from a parsed HTML document.
    # Strategy: try structured extraction first, fall back to full-page text.
    def extract_menu_text(doc, url)
      # Remove noise elements
      doc.css('script, style, noscript, svg, iframe, nav, footer, header').each(&:remove)

      # Materialize Alpine.js x-text price values into visible text before stripping
      # Pattern: x-text="(new Intl.NumberFormat('en-IE', { style: 'currency', currency: 'EUR' }).format('15'))"
      doc.css('[x-text]').each do |node|
        xtext = node['x-text'].to_s
        if xtext.include?('currency') && (m = xtext.match(/currency:\s*'(\w+)'.*?format\(\s*'([\d.]+)'\s*\)/))
          currency_code, amount = m[1], m[2]
          symbol = { 'EUR' => '€', 'GBP' => '£', 'USD' => '$', 'CZK' => 'Kč' }[currency_code] || currency_code
          node.content = "#{symbol}#{amount}"
        end
      end

      # Strip Alpine.js / Vue / React inline event attributes that leak into text
      doc.css('[x-data], [x-show], [x-text], [x-bind], [@click], [@mouseleave], [@mouseenter]').each do |node|
        %w[x-data x-show x-text x-bind x-init @click @mouseleave @mouseenter @mouseover].each do |attr|
          node.remove_attribute(attr)
        end
      end

      # 1. Try targeted menu containers first
      text = extract_from_menu_containers(doc)
      return text if text.present? && text.length >= 100

      # 2. Try main content area
      text = extract_from_main_content(doc)
      return text if text.present? && text.length >= 100

      # 3. Fall back to body text
      extract_body_text(doc)
    end

    def extract_from_menu_containers(doc)
      selectors = [
        '[class*="menu-section"]', '[class*="menu-category"]', '[class*="menu-item"]',
        '[class*="food-menu"]', '[class*="drink-menu"]', '[class*="wine-list"]',
        '[id*="menu"]', '[class*="menu-list"]', '[class*="menu-content"]',
        '.menu', '#menu', '.carte', '.speisekarte',
        '[data-menu]', '[data-category]',
      ]

      candidates = []
      selectors.each do |sel|
        doc.css(sel).each do |node|
          text = clean_node_text(node)
          candidates << text if text.present? && text.length >= 50
        end
      end

      return nil if candidates.empty?

      # Deduplicate: if a parent container already captured child content, prefer the parent
      candidates.uniq.sort_by(&:length).reverse.first(5).join("\n\n")
    end

    def extract_from_main_content(doc)
      selectors = %w[main article [role="main"] .content #content .page-content .entry-content]
      selectors.each do |sel|
        node = doc.at_css(sel)
        next unless node

        text = clean_node_text(node)
        return text if text.present? && text.length >= 100
      end

      nil
    end

    def extract_body_text(doc)
      body = doc.at_css('body')
      return nil unless body

      text = clean_node_text(body)
      text.present? && text.length >= 100 ? text[0, 15_000] : nil
    end

    # Convert a Nokogiri node to clean text preserving structure hints.
    # Headings become "## Heading", list items get "- " prefix, etc.
    def clean_node_text(node)
      lines = []

      node.traverse do |child|
        next unless child.text?

        text = child.text.to_s.gsub(/\s+/, ' ').strip
        next if text.blank?

        # Skip JavaScript-like content
        next if javascript_artifact?(text)

        parent = child.parent
        tag = parent&.name.to_s.downcase

        case tag
        when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
          lines << "\n## #{text}"
        when 'li'
          lines << "- #{text}"
        when 'dt'
          lines << "\n#{text}"
        when 'dd'
          lines << "  #{text}"
        when 'p', 'div', 'span', 'td', 'th', 'a', 'strong', 'em', 'b', 'i'
          lines << text
        else
          lines << text
        end
      end

      result = lines.join("\n").gsub(/\n{3,}/, "\n\n").strip
      result = clean_javascript_noise(result)
      result.present? ? result[0, 15_000] : nil
    end

    # Detect text nodes that are JavaScript code rather than menu content
    def javascript_artifact?(text)
      return true if text.match?(/\{\s*(var |let |const |return |function |focusImage|focusTitle|currentMain)/)
      return true if text.match?(/@mouse(leave|enter|over)\s*=/)
      return true if text.match?(/\(\(\)\s*=>/)
      return true if text.match?(/document\.querySelector/)
      return true if text.match?(/\.scrollIntoView/)
      return true if text.match?(/element\.scroll/)

      false
    end

    # Remove residual JavaScript patterns from extracted text
    def clean_javascript_noise(text)
      result = text.to_s
      # Remove Alpine.js / JS template expressions: { ... })" or similar
      result = result.gsub(/\{\s*(?:var|let|const|return|focusImage|focusTitle|currentMain)[^}]*\}\)?\"?\s*/m, '')
      # Remove @event handlers that leaked
      result = result.gsub(/@(?:click|mouseleave|mouseenter|mouseover)="[^"]*"\s*/m, '')
      # Remove orphaned closing patterns
      result = result.gsub(/\)\"\s*>/, '')
      # Clean up excessive whitespace from removals
      result = result.gsub(/\n{3,}/, "\n\n").strip
      result
    end
  end
end
