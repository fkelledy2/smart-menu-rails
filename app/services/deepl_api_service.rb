# app/services/deepl_api_service.rb
require 'httparty'

class DeeplApiService
  include HTTParty

  base_uri 'https://api-free.deepl.com/v2'

  def self.translate(text, to: 'FR', from: 'EN')
    api_key = Rails.application.credentials.dig(:deepl, :api_key) || ENV['DEEPL_API_KEY']
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
