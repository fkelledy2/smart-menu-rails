# app/services/deepl_api_service.rb
require 'httparty'

class DeeplApiService
  include HTTParty

  base_uri 'https://api-free.deepl.com/v2'

  TEST_API_KEY = '9079cde6-1153-4f72-a220-306de587c58e:fx'.freeze

  def self.translate(text, to: 'FR', from: 'EN')
    api_key = Rails.application.credentials.dig(:deepl, :api_key) || ENV['DEEPL_API_KEY']
    api_key = TEST_API_KEY if api_key.to_s.strip == '' && Rails.env.test?
    raise 'DEEPL_API_KEY missing' if api_key.to_s.strip == ''

    response = post('/translate', {
      body: {
        auth_key: api_key,
        text: text,
        source_lang: from,
        target_lang: to,
      },
    },)

    raise "DeepL API error: #{response.code} - #{response.body}" unless response.success?

    response.parsed_response['translations'].first['text']
  end
end
