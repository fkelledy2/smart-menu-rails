# DeepL Translation API client with proper error handling and configuration
class DeeplClient < ExternalApiClient
  # DeepL specific exceptions
  class TranslationError < ApiError; end
  class UnsupportedLanguageError < Error; end
  class QuotaExceededError < RateLimitError; end

  # Supported language codes
  SUPPORTED_LANGUAGES = {
    'BG' => 'Bulgarian',
    'CS' => 'Czech',
    'DA' => 'Danish',
    'DE' => 'German',
    'EL' => 'Greek',
    'EN' => 'English',
    'ES' => 'Spanish',
    'ET' => 'Estonian',
    'FI' => 'Finnish',
    'FR' => 'French',
    'HU' => 'Hungarian',
    'ID' => 'Indonesian',
    'IT' => 'Italian',
    'JA' => 'Japanese',
    'KO' => 'Korean',
    'LT' => 'Lithuanian',
    'LV' => 'Latvian',
    'NB' => 'Norwegian',
    'NL' => 'Dutch',
    'PL' => 'Polish',
    'PT' => 'Portuguese',
    'RO' => 'Romanian',
    'RU' => 'Russian',
    'SK' => 'Slovak',
    'SL' => 'Slovenian',
    'SV' => 'Swedish',
    'TR' => 'Turkish',
    'UK' => 'Ukrainian',
    'ZH' => 'Chinese',
  }.freeze

  # Translate text from one language to another
  # @param text [String] Text to translate
  # @param to [String] Target language code
  # @param from [String] Source language code (optional, auto-detect if nil)
  # @return [String] Translated text
  def translate(text, to:, from: nil)
    validate_language_codes!(to, from)

    body = {
      auth_key: config[:api_key],
      text: text,
      target_lang: to.upcase,
    }
    body[:source_lang] = from.upcase if from.present?

    response = post('/translate', { body: body })

    extract_translation(response)
  rescue ApiError => e
    handle_deepl_error(e)
  end

  # Get usage statistics
  # @return [Hash] Usage information including character count and limit
  def usage
    response = post('/usage', {
      body: { auth_key: config[:api_key] },
    },)

    response.parsed_response
  end

  # Get supported languages
  # @param type [String] 'source' or 'target' languages
  # @return [Array<Hash>] Array of supported languages with codes and names
  def supported_languages(type: 'target')
    response = get('/languages', {
      query: {
        auth_key: config[:api_key],
        type: type,
      },
    },)

    response.parsed_response
  end

  protected

  def default_config
    super.merge(
      base_uri: deepl_base_uri,
      api_key: deepl_api_key,
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded',
      },
      health_check_endpoint: '/usage',
    )
  end

  def validate_config!
    super
    raise ConfigurationError, 'DeepL API key is required' unless config[:api_key]
  end

  def handle_response(response)
    case response.code
    when 456
      raise QuotaExceededError, 'DeepL quota exceeded'
    else
      super
    end
  end

  private

  def deepl_base_uri
    # Use free or pro API based on key format
    if deepl_api_key&.end_with?(':fx')
      'https://api-free.deepl.com/v2'
    else
      'https://api.deepl.com/v2'
    end
  end

  def deepl_api_key
    Rails.application.credentials.deepl_api_key || ENV.fetch('DEEPL_API_KEY', nil)
  end

  def validate_language_codes!(to, from)
    raise UnsupportedLanguageError, "Unsupported target language: #{to}" unless SUPPORTED_LANGUAGES.key?(to.upcase)

    if from.present? && !SUPPORTED_LANGUAGES.key?(from.upcase)
      raise UnsupportedLanguageError,
            "Unsupported source language: #{from}"
    end
  end

  def extract_translation(response)
    translations = response.parsed_response['translations']
    raise TranslationError, 'No translations returned' if translations.blank?

    translations.first['text']
  end

  def handle_deepl_error(error)
    case error.message
    when /quota/i
      raise QuotaExceededError, 'DeepL translation quota exceeded'
    when /language/i
      raise UnsupportedLanguageError, 'Unsupported language pair'
    else
      raise TranslationError, "Translation failed: #{error.message}"
    end
  end

  def build_request_options(options)
    # DeepL uses form-encoded data, not JSON
    request_options = super

    if request_options[:body].is_a?(Hash)
      request_options[:body] = URI.encode_www_form(request_options[:body])
    end

    request_options
  end

  def auth_headers
    {} # DeepL uses auth_key in body, not headers
  end
end
