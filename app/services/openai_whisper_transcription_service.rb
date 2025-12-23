require 'httparty'

class OpenaiWhisperTranscriptionService
  include HTTParty
  base_uri 'https://api.openai.com'

  def initialize(api_key: nil, model: nil)
    @api_key = api_key || Rails.application.credentials.openai_api_key || ENV['OPENAI_API_KEY']
    @model = model || Rails.application.credentials.dig(:openai, :whisper_model) || ENV['OPENAI_WHISPER_MODEL'] || 'whisper-1'
  end

  def transcribe(file_path:, language: nil)
    raise 'OPENAI_API_KEY missing' if @api_key.blank?

    headers = {
      'Authorization' => "Bearer #{@api_key}",
    }

    options = {
      headers: headers,
      multipart: true,
      body: {
        model: @model,
        file: File.open(file_path, 'rb'),
      },
    }

    options[:body][:language] = language if language.present?

    resp = self.class.post('/v1/audio/transcriptions', options)
    unless resp.respond_to?(:success?) && resp.success?
      raise "OpenAI transcription failed: status=#{resp.code} body=#{resp.body.to_s[0, 500]}"
    end

    json = resp.parsed_response
    (json.is_a?(Hash) ? (json['text'] || json.dig('data', 'text')) : nil).to_s
  end
end
