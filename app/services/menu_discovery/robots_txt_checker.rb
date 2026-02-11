module MenuDiscovery
  class RobotsTxtChecker
    USER_AGENT = 'SmartMenuBot'.freeze
    CACHE_TTL = 1.hour

    def initialize(http_client: HTTParty)
      @http_client = http_client
      @cache = {}
    end

    # Returns true if the given URL is allowed to be crawled by our bot.
    # Checks robots.txt rules for our user-agent and falls back to '*'.
    def allowed?(url)
      uri = URI.parse(url.to_s)
      return true if uri.host.blank?

      robots_url = "#{uri.scheme}://#{uri.host}/robots.txt"
      rules = fetch_rules(robots_url)

      return true if rules.nil? # No robots.txt or fetch failed → allowed

      path = uri.path.to_s
      path = '/' if path.blank?

      check_rules(rules, path)
    rescue StandardError
      true # Fail open — if we can't parse, allow
    end

    # Returns a hash of crawl evidence for storage in metadata.
    def evidence(url)
      uri = URI.parse(url.to_s)
      return { 'robots_txt' => 'no_host' } if uri.host.blank?

      robots_url = "#{uri.scheme}://#{uri.host}/robots.txt"
      raw = fetch_raw(robots_url)

      if raw.nil?
        return { 'robots_txt' => 'not_found', 'robots_checked_at' => Time.current.iso8601 }
      end

      allowed = allowed?(url)

      {
        'robots_txt' => 'found',
        'robots_allowed' => allowed,
        'robots_checked_at' => Time.current.iso8601,
      }
    rescue StandardError => e
      { 'robots_txt' => 'error', 'robots_error' => e.message, 'robots_checked_at' => Time.current.iso8601 }
    end

    private

    def fetch_rules(robots_url)
      return @cache[robots_url][:rules] if @cache[robots_url] && @cache[robots_url][:fetched_at] > CACHE_TTL.ago

      raw = fetch_raw(robots_url)
      rules = raw ? parse(raw) : nil
      @cache[robots_url] = { rules: rules, fetched_at: Time.current }
      rules
    end

    def fetch_raw(robots_url)
      resp = @http_client.get(robots_url, headers: {
        'User-Agent' => "#{USER_AGENT}/1.0 (+https://www.mellow.menu)",
        'Accept' => 'text/plain',
      }, timeout: 10,)

      return nil unless resp.respond_to?(:code) && resp.code.to_i == 200

      resp.body.to_s
    rescue StandardError
      nil
    end

    def parse(raw)
      rules = { '*' => { allow: [], disallow: [] } }
      current_agents = []

      raw.each_line do |line|
        line = line.split('#').first.to_s.strip
        next if line.blank?

        if line.match?(/\AUser-agent:\s*/i)
          agent = line.sub(/\AUser-agent:\s*/i, '').strip.downcase
          current_agents << agent
          rules[agent] ||= { allow: [], disallow: [] }
        elsif line.match?(/\ADisallow:\s*/i) && current_agents.any?
          path = line.sub(/\ADisallow:\s*/i, '').strip
          current_agents.each { |a| rules[a][:disallow] << path } if path.present?
        elsif line.match?(/\AAllow:\s*/i) && current_agents.any?
          path = line.sub(/\AAllow:\s*/i, '').strip
          current_agents.each { |a| rules[a][:allow] << path } if path.present?
        else
          current_agents = [] unless line.match?(/\A(User-agent|Disallow|Allow|Sitemap|Crawl-delay):/i)
        end
      end

      rules
    end

    def check_rules(rules, path)
      # Check our specific user-agent first, then fall back to '*'
      agent_key = rules.keys.find { |k| USER_AGENT.downcase.include?(k) && k != '*' }
      agent_rules = rules[agent_key] || rules['*']

      return true if agent_rules.nil?

      # Check explicit allows first (longer match wins)
      best_allow = agent_rules[:allow].select { |p| path_matches?(path, p) }.max_by(&:length)
      best_disallow = agent_rules[:disallow].select { |p| path_matches?(path, p) }.max_by(&:length)

      return true if best_disallow.nil?
      return true if best_allow && best_allow.length >= best_disallow.length

      false
    end

    def path_matches?(path, pattern)
      return false if pattern.blank?

      if pattern.end_with?('$')
        path == pattern.chomp('$')
      elsif pattern.include?('*')
        regex = Regexp.new('\A' + Regexp.escape(pattern).gsub('\*', '.*') + '.*\z')
        path.match?(regex)
      else
        path.start_with?(pattern)
      end
    rescue StandardError
      false
    end
  end
end
