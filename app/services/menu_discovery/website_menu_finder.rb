require 'nokogiri'
require 'set'

module MenuDiscovery
  class WebsiteMenuFinder
    DEFAULT_MAX_PAGES = 12

    def initialize(base_url:, http_client: HTTParty)
      @base_url = normalize_url(base_url)
      @http_client = http_client

      raise ArgumentError, 'base_url required' if @base_url.blank?
    end

    def find_menu_pdfs(max_pages: DEFAULT_MAX_PAGES)
      max = max_pages.to_i
      max = DEFAULT_MAX_PAGES if max <= 0

      base_uri = URI.parse(@base_url)
      host = base_uri.host

      visited = Set.new
      queue = []

      queue << @base_url
      discovered_pdfs = Set.new

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

        links = doc.css('a[href]').map { |a| a['href'].to_s }.map(&:strip).reject(&:blank?)

        links.each do |href|
          abs = absolutize(base_uri: base_uri, href: href)
          next if abs.nil?
          next unless abs.host == host

          if abs.path.to_s.downcase.end_with?('.pdf')
            discovered_pdfs << abs.to_s
            next
          end

          next unless looks_like_menu_page?(abs)

          queue << abs.to_s
        end
      end

      discovered_pdfs.to_a
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

    def absolutize(base_uri:, href:)
      return nil if href.blank?
      return nil if href.start_with?('mailto:') || href.start_with?('tel:') || href.start_with?('javascript:')

      URI.join(base_uri.to_s, href)
    rescue URI::InvalidURIError
      nil
    end

    def looks_like_menu_page?(uri)
      path = uri.path.to_s.downcase
      query = uri.query.to_s.downcase

      return true if path.include?('menu') || path.include?('menus')
      return true if query.include?('menu')

      false
    end

    def noindex?(doc:)
      robots = doc.at_css('meta[name="robots"]')&.[]('content').to_s.downcase
      return true if robots.include?('noindex')

      false
    end
  end
end
