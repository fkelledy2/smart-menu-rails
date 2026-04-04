# app/services/deepl_api_service.rb
require 'httparty'

class DeeplApiService
  include HTTParty

  # base_uri is set dynamically per request based on key type (see .base_uri_for_key)
  base_uri 'https://api-free.deepl.com/v2'

  class MissingApiKeyError < StandardError; end

  def self.api_key
    (Rails.application.credentials.dig(:deepl, :api_key) ||
      Rails.application.credentials.deepl_api_key ||
      ENV.fetch('DEEPL_API_KEY', nil)).to_s.strip
  end

  def self.base_uri_for_key(key)
    key.to_s.end_with?(':fx') ? 'https://api-free.deepl.com/v2' : 'https://api.deepl.com/v2'
  end

  def self.api_key_with_test_fallback
    key = api_key
    return Rails.application.credentials.dig(:deepl, :test_api_key).to_s if key.blank? && Rails.env.test?

    key
  end

  def self.configured?
    api_key_with_test_fallback.present?
  end

  def self.translate(text, to: 'FR', from: 'EN')
    key = api_key
    raise MissingApiKeyError, 'DEEPL_API_KEY missing' if key.blank?

    # Route to the correct endpoint: free keys end with ':fx' and use api-free.deepl.com;
    # pro keys use api.deepl.com. HTTParty.post with a full absolute URL bypasses base_uri.
    endpoint = "#{base_uri_for_key(key)}/translate"

    response = post(endpoint, {
      headers: { 'Authorization' => "DeepL-Auth-Key #{key}" },
      body: {
        text: text,
        source_lang: from,
        target_lang: to,
      },
    })

    raise "DeepL API error: #{response.code} - #{response.body}" unless response.success?

    response.parsed_response['translations'].first['text']
  end
end
