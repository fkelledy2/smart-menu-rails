# app/services/deepl_api_service.rb
require 'httparty'

class DeeplApiService
  include HTTParty

  base_uri 'https://api-free.deepl.com/v2'

  def self.translate(text, to: 'FR', from: 'EN')
    response = post('/translate', {
      body: {
        auth_key: '9079cde6-1153-4f72-a220-306de587c58e:fx',
        text: text,
        source_lang: from,
        target_lang: to,
      },
    },)

    raise "DeepL API error: #{response.code} - #{response.body}" unless response.success?

    response.parsed_response['translations'].first['text']
  end
end
