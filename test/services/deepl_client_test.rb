require 'test_helper'

class DeeplClientTest < ActiveSupport::TestCase
  setup do
    # Set ENV variable to provide API key
    ENV['DEEPL_API_KEY'] = 'test-api-key'
    @client = DeeplClient.new
  end

  teardown do
    ENV.delete('DEEPL_API_KEY')
  end

  test 'has supported languages defined' do
    assert_not_empty DeeplClient::SUPPORTED_LANGUAGES
    assert_includes DeeplClient::SUPPORTED_LANGUAGES.keys, 'EN'
    assert_includes DeeplClient::SUPPORTED_LANGUAGES.keys, 'ES'
    assert_includes DeeplClient::SUPPORTED_LANGUAGES.keys, 'FR'
  end

  test 'validates supported target language' do
    assert_raises(DeeplClient::UnsupportedLanguageError) do
      @client.send(:validate_language_codes!, 'XX', nil)
    end
  end

  test 'validates supported source language' do
    assert_raises(DeeplClient::UnsupportedLanguageError) do
      @client.send(:validate_language_codes!, 'EN', 'XX')
    end
  end

  test 'accepts valid language codes' do
    assert_nothing_raised do
      @client.send(:validate_language_codes!, 'EN', 'ES')
    end
  end

  test 'accepts nil source language for auto-detection' do
    assert_nothing_raised do
      @client.send(:validate_language_codes!, 'EN', nil)
    end
  end

  test 'determines free API base URI' do
    ENV['DEEPL_API_KEY'] = 'test-key:fx'
    client = DeeplClient.new
    base_uri = client.send(:deepl_base_uri)

    assert_equal 'https://api-free.deepl.com/v2', base_uri
  ensure
    ENV['DEEPL_API_KEY'] = 'test-api-key'
  end

  test 'determines pro API base URI' do
    ENV['DEEPL_API_KEY'] = 'test-key'
    client = DeeplClient.new
    base_uri = client.send(:deepl_base_uri)

    assert_equal 'https://api.deepl.com/v2', base_uri
  ensure
    ENV['DEEPL_API_KEY'] = 'test-api-key'
  end

  test 'builds form-encoded request body' do
    options = { body: { text: 'Hello', target_lang: 'ES' } }
    request_options = @client.send(:build_request_options, options)

    assert_kind_of String, request_options[:body]
    assert_includes request_options[:body], 'text=Hello'
  end

  test 'handles translation error' do
    error = DeeplClient::ApiError.new('Translation failed')

    assert_raises(DeeplClient::TranslationError) do
      @client.send(:handle_deepl_error, error)
    end
  end

  test 'handles quota exceeded error' do
    error = DeeplClient::ApiError.new('Quota exceeded')

    assert_raises(DeeplClient::QuotaExceededError) do
      @client.send(:handle_deepl_error, error)
    end
  end

  test 'handles unsupported language error' do
    error = DeeplClient::ApiError.new('Unsupported language')

    assert_raises(DeeplClient::UnsupportedLanguageError) do
      @client.send(:handle_deepl_error, error)
    end
  end

  test 'extracts translation from response' do
    response = OpenStruct.new(
      parsed_response: {
        'translations' => [
          { 'text' => 'Hola', 'detected_source_language' => 'EN' },
        ],
      },
    )

    translation = @client.send(:extract_translation, response)
    assert_equal 'Hola', translation
  end

  test 'raises error when no translations returned' do
    response = OpenStruct.new(parsed_response: { 'translations' => [] })

    assert_raises(DeeplClient::TranslationError) do
      @client.send(:extract_translation, response)
    end
  end

  test 'auth headers are empty for DeepL' do
    headers = @client.send(:auth_headers)
    assert_empty headers
  end

  test 'default config includes DeepL specific settings' do
    config = @client.send(:default_config)

    assert_includes config[:headers]['Content-Type'], 'application/x-www-form-urlencoded'
    assert_equal '/usage', config[:health_check_endpoint]
  end
end
