# frozen_string_literal: true

module VendorUsage
  # Polls the DeepL usage API and stores daily usage records.
  class DeeplIngestionService
    DEEPL_USAGE_URL = 'https://api-free.deepl.com/v2/usage'
    DEEPL_PRO_USAGE_URL = 'https://api.deepl.com/v2/usage'

    Result = Struct.new(:usage, :error, keyword_init: true) do
      def success?
        error.nil?
      end
    end

    def self.ingest(date: Date.current)
      new.ingest(date: date)
    end

    def ingest(date: Date.current)
      api_key = DeeplApiService.api_key
      return Result.new(usage: nil, error: 'DeepL API key not configured') if api_key.blank?

      usage_data = fetch_usage(api_key)
      return Result.new(usage: nil, error: usage_data[:error]) if usage_data[:error]

      # DeepL usage API returns cumulative character counts for the billing period.
      # We record the snapshot for the given date.
      char_count  = usage_data[:character_count].to_i
      char_limit  = usage_data[:character_limit].to_i

      ExternalServiceDailyUsage.upsert_usage(
        date: date,
        service: 'deepl',
        dimension: 'character_count',
        units: char_count,
        unit_type: 'characters',
        metadata: {
          character_limit: char_limit,
          utilization_pct: char_limit.positive? ? (char_count.to_f / char_limit * 100).round(2) : 0,
        },
      )

      Result.new(
        usage: { character_count: char_count, character_limit: char_limit },
        error: nil,
      )
    rescue StandardError => e
      Rails.logger.error("[VendorUsage::DeeplIngestionService] #{e.class}: #{e.message}")
      Result.new(usage: nil, error: e.message)
    end

    private

    def fetch_usage(api_key)
      url = api_key.end_with?(':fx') ? DEEPL_USAGE_URL : DEEPL_PRO_USAGE_URL

      response = HTTParty.get(url, headers: { 'Authorization' => "DeepL-Auth-Key #{api_key}" })

      unless response.success?
        return { error: "DeepL usage API returned #{response.code}: #{response.body}" }
      end

      data = response.parsed_response
      {
        character_count: data['character_count'],
        character_limit: data['character_limit'],
      }
    end
  end
end
