# app/services/deepl_api_service.rb
require 'httparty'

class DeeplApiService
  include HTTParty

  base_uri 'https://api-free.deepl.com/v2'

  TEST_API_KEY = '9079cde6-1153-4f72-a220-306de587c58e:fx'.freeze

  class MissingApiKeyError < StandardError; end

  def self.api_key
    key = Rails.application.credentials.dig(:deepl, :api_key) || ENV['DEEPL_API_KEY']
    key = TEST_API_KEY if key.to_s.strip == '' && Rails.env.test?
    key.to_s.strip
  end

  def self.configured?
    api_key.present?
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
    },)

    raise "DeepL API error: #{response.code} - #{response.body}" unless response.success?

    response.parsed_response['translations'].first['text']
  end
end
