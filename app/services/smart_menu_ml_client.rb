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

    raise "ML rerank failed: HTTP #{r.code}" unless r.code.to_i >= 200 && r.code.to_i < 300

    data = r.parsed_response
    ranked = data.is_a?(Hash) ? data['ranked'] : nil
    raise 'ML rerank failed: invalid response' unless ranked.is_a?(Array)

    ranked
  end
end
