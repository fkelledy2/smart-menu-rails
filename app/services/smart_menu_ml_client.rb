require 'httparty'

class SmartMenuMlClient
  include HTTParty

  def initialize(base_url: ENV['SMART_MENU_ML_URL'].to_s)
    @base_url = base_url.to_s.chomp('/')
  end

  def enabled?
    @base_url.present?
  end

  def embed(texts:, locale: nil)
    return nil if @base_url.blank?

    r = self.class.post(
      "#{@base_url}/embed",
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' },
      body: { texts: texts, locale: locale }.to_json,
      timeout: (ENV['SMART_MENU_ML_TIMEOUT_SECONDS'].presence || 0.25).to_f
    )

    log_response('embed', r)

    raise "ML embed failed: HTTP #{r.code}" unless r.code.to_i >= 200 && r.code.to_i < 300

    data = r.parsed_response
    vectors = data.is_a?(Hash) ? data['vectors'] : nil
    raise 'ML embed failed: invalid response' unless vectors.is_a?(Array)

    vectors
  end

  def rerank(query:, candidates:, locale: nil)
    return nil if @base_url.blank?

    r = self.class.post(
      "#{@base_url}/rerank",
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' },
      body: { query: query, candidates: candidates, locale: locale }.to_json,
      timeout: (ENV['SMART_MENU_ML_TIMEOUT_SECONDS'].presence || 0.25).to_f
    )

    log_response('rerank', r)

    raise "ML rerank failed: HTTP #{r.code}" unless r.code.to_i >= 200 && r.code.to_i < 300

    data = r.parsed_response
    ranked = data.is_a?(Hash) ? data['ranked'] : nil
    raise 'ML rerank failed: invalid response' unless ranked.is_a?(Array)

    ranked
  end

  private

  def log_response(endpoint, response)
    return unless ml_logging_enabled?

    code = response.respond_to?(:code) ? response.code : nil
    parsed = begin
      response.respond_to?(:parsed_response) ? response.parsed_response : nil
    rescue StandardError
      nil
    end
    body_preview = summarize_payload(parsed)
    logger.info("[SmartMenuMlClient] #{endpoint} -> HTTP #{code}; response=#{body_preview}")
  rescue StandardError
    nil
  end

  def ml_logging_enabled?
    v = ENV['SMART_MENU_ML_LOG_RESPONSES']
    return false if v.nil? || v.to_s.strip == ''
    v.to_s.strip.downcase == 'true'
  end

  def logger
    if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
      Rails.logger
    else
      Logger.new($stdout)
    end
  end

  def summarize_payload(payload)
    max = (ENV['SMART_MENU_ML_LOG_MAX_CHARS'].presence || 800).to_i

    if payload.is_a?(Hash)
      if payload.key?('vectors') && payload['vectors'].is_a?(Array)
        vectors = payload['vectors']
        dims = vectors.first.is_a?(Array) ? vectors.first.length : nil
        return "{vectors_count=#{vectors.length}, dims=#{dims}}"
      end
      if payload.key?('ranked') && payload['ranked'].is_a?(Array)
        ids = payload['ranked'].first(3).map { |x| x.is_a?(Hash) ? (x['id'] || x[:id]) : nil }.compact
        return "{ranked_count=#{payload['ranked'].length}, top_ids=#{ids}}"
      end
      return truncate_str(payload.to_json, max)
    end

    if payload.is_a?(Array)
      return truncate_str(payload.to_json, max)
    end

    truncate_str(payload.to_s, max)
  rescue StandardError
    truncate_str(payload.to_s, max)
  end

  def truncate_str(s, max)
    str = s.to_s
    return str if max <= 0
    return str if str.length <= max
    "#{str[0, max]}…"
  end
end
