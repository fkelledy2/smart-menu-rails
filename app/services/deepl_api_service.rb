# app/services/deepl_api_service.rb
require 'httparty'

class DeeplApiService
  include HTTParty

  base_uri 'https://api-free.deepl.com/v2'

  class MissingApiKeyError < StandardError; end

  def self.api_key
    (Rails.application.credentials.dig(:deepl, :api_key) || ENV.fetch('DEEPL_API_KEY', nil)).to_s.strip
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

    response = post('/translate', {
      body: {
        auth_key: key,
        text: text,
        source_lang: from,
        target_lang: to,
      },
    })

    raise "DeepL API error: #{response.code} - #{response.body}" unless response.success?

    response.parsed_response['translations'].first['text']
  end
end
