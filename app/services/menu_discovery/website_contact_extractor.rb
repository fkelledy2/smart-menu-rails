require 'nokogiri'
require 'set'
require 'cgi'

module MenuDiscovery
  class WebsiteContactExtractor
    DEFAULT_MAX_PAGES = 8

    DEFAULT_PATH_HINTS = %w[
      /
      /contact
      /contact-us
      /contacts
      /kontakt
      /contatto
      /contacto
      /kapcsolat
      /elerhetoseg
      /elerhetosegek
      /reservation
      /reservations
      /book
      /booking
      /find-us
      /location
      /locations
      /about
      /about-us
      /impressum
      /legal
      /privacy
      /terms
    ].freeze

    def initialize(base_url:, http_client: HTTParty)
      @base_url = normalize_url(base_url)
      @http_client = http_client

      raise ArgumentError, 'base_url required' if @base_url.blank?
    end

    def extract(max_pages: DEFAULT_MAX_PAGES)
      max = max_pages.to_i
      max = DEFAULT_MAX_PAGES if max <= 0

      base_uri = URI.parse(@base_url)
      host = base_uri.host

      visited = Set.new
      queue = []

      DEFAULT_PATH_HINTS.each do |path|
        begin
          queue << URI.join(base_uri.to_s, path).to_s
        rescue URI::InvalidURIError
          next
        end
      end

      emails = Set.new
      phones = Set.new
      address_candidates = []
      type_context = Set.new
      about_pages = []
      homepage_text = nil
      social_links = Set.new

      while queue.any? && visited.size < max
        url = queue.shift
        next if visited.include?(url)

        visited << url

        html = fetch_html(url)
        next if html.blank?

        doc = Nokogiri::HTML(html)

        if noindex?(doc: doc)
          next
        end

        extract_from_doc(doc: doc, emails: emails, phones: phones, address_candidates: address_candidates, type_context: type_context, social_links: social_links)

        u_lower = url.to_s.downcase
        is_about = u_lower.include?('about') || u_lower.include?('our-story') || u_lower.include?('story')
        is_home  = URI.parse(url).path.to_s.chomp('/').blank? rescue false

        page_text = extract_page_text(doc: doc)
        if page_text.present?
          if is_about
            about_pages << { 'url' => url, 'text' => page_text }
          elsif is_home
            homepage_text = page_text
          end
        end

        next_urls = extract_internal_links(doc: doc, base_uri: base_uri, host: host)
        next_urls.each do |u|
          queue << u unless visited.include?(u)
        end
      end

      {
        'source_base_url' => @base_url,
        'visited_urls' => visited.to_a,
        'emails' => emails.to_a.first(10),
        'phones' => phones.to_a.first(10),
        'address_candidates' => address_candidates.uniq.first(5),
        'context_types' => type_context.to_a,
        'social_links' => social_links.to_a.first(10),
        'about' => best_about_page(about_pages),
        'homepage_text' => homepage_text,
        'extracted_at' => Time.current.iso8601,
      }
    end

    private

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
      }, timeout: 20)

      return nil unless resp.respond_to?(:code)
      return nil unless resp.code.to_i >= 200 && resp.code.to_i < 300

      content_type = resp.headers['content-type'].to_s
      return nil unless content_type.include?('text/html') || content_type == ''

      resp.body.to_s
    rescue StandardError
      nil
    end

    def noindex?(doc:)
      robots = doc.at_css('meta[name="robots"]')&.[]('content').to_s.downcase
      return true if robots.include?('noindex')

      false
    end

    SOCIAL_DOMAINS = %w[
      instagram.com facebook.com twitter.com x.com
      tripadvisor.com tripadvisor.co.uk tripadvisor.ie
      linkedin.com yelp.com
    ].freeze

    def extract_from_doc(doc:, emails:, phones:, address_candidates:, type_context:, social_links: nil)
      mailtos = doc.css('a[href^="mailto:"]').map { |a| a['href'].to_s }.map(&:strip)
      mailtos.each do |href|
        email = href.sub(/^mailto:/i, '').split('?').first.to_s.strip
        emails << email.downcase if email.match?(/\A[^\s@]+@[^\s@]+\.[^\s@]+\z/)
      end

      tels = doc.css('a[href^="tel:"]').map { |a| a['href'].to_s }.map(&:strip)
      tels.each do |href|
        phone = href.sub(/^tel:/i, '').split('?').first.to_s.strip
        normalized = normalize_phone(phone)
        phones << normalized if normalized.present?
      end

      text = doc.text.to_s

      begin
        EstablishmentTypeInference.new.infer_from_text(text).each { |t| type_context << t }
      rescue StandardError
        nil
      end

      text.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i).each do |email|
        emails << email.downcase
      end

      text.scan(/(\+?\d[\d\s().-]{6,}\d)/).flatten.each do |phone|
        normalized = normalize_phone(phone)
        phones << normalized if normalized.present?
      end

      doc.css('address').each do |addr|
        t = addr.text.to_s.gsub(/\s+/, ' ').strip
        address_candidates << t if t.present?
      end

      doc.css('[class],[id]').each do |node|
        klass = node['class'].to_s
        ident = node['id'].to_s
        next unless klass.downcase.include?('address') || ident.downcase.include?('address')

        t = node.text.to_s.gsub(/\s+/, ' ').strip
        address_candidates << t if t.present? && t.length <= 220
      end

      if social_links
        doc.css('a[href]').each do |a|
          href = a['href'].to_s.strip
          next if href.blank?

          begin
            uri = URI.parse(href)
            host = uri.host.to_s.downcase.sub(/\Awww\./, '')
            social_links << href if SOCIAL_DOMAINS.include?(host)
          rescue URI::InvalidURIError
            next
          end
        end
      end

      nil
    end

    def normalize_phone(phone)
      p = CGI.unescape(phone.to_s)
      p = p.gsub(/[\u00A0\s]+/, ' ').strip
      p = p.gsub(/[^0-9+() .-]/, '')
      p = p.gsub(/\s+/, ' ').strip
      return nil if p.blank?

      digits = p.gsub(/\D/, '')
      return nil if digits.length < 7

      p
    end

    def extract_page_text(doc:)
      return nil if doc.nil?

      begin
        doc.css('script,style,noscript,svg').remove
      rescue StandardError
        nil
      end

      candidates = []

      doc.css('main, article, [role="main"], .content, #content, .page-content, .entry-content').each do |node|
        t = node.text.to_s.gsub(/\s+/, ' ').strip
        candidates << t if t.length >= 120
      end

      if candidates.empty?
        t = doc.text.to_s.gsub(/\s+/, ' ').strip
        candidates << t if t.length >= 120
      end

      best = candidates.max_by { |t| t.length }
      return nil if best.blank?

      best = best[0, 2000]
      best
    rescue StandardError
      nil
    end

    def best_about_page(about_pages)
      pages = Array(about_pages)
      return nil if pages.empty?

      pages.max_by { |p| p.is_a?(Hash) ? p.fetch('text', '').to_s.length : 0 }
    rescue StandardError
      nil
    end

    def extract_internal_links(doc:, base_uri:, host:)
      links = doc.css('a[href]').map { |a| a['href'].to_s }.map(&:strip).reject(&:blank?)

      urls = []
      links.each do |href|
        next if href.start_with?('mailto:') || href.start_with?('tel:') || href.start_with?('javascript:')

        begin
          abs = URI.join(base_uri.to_s, href)
        rescue URI::InvalidURIError
          next
        end

        next unless abs.host == host

        path = abs.path.to_s
        next if path.downcase.end_with?('.pdf')

        if looks_like_contact_page?(abs)
          urls << abs.to_s
        end
      end

      urls.uniq
    end

    def looks_like_contact_page?(uri)
      path = uri.path.to_s.downcase
      query = uri.query.to_s.downcase

      return true if path.include?('contact') || path.include?('about') || path.include?('impressum')
      return true if path.include?('legal') || path.include?('privacy') || path.include?('terms')
      return true if query.include?('contact')

      false
    end
  end
end
