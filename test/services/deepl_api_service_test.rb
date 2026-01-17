require 'test_helper'

class DeeplApiServiceTest < ActiveSupport::TestCase
  def setup
    # Store original HTTParty methods for restoration
    @original_post = DeeplApiService.method(:post)
  end

  def teardown
    # Clean up any test data if needed
  end

  # Basic functionality tests
  test 'should include HTTParty module' do
    assert DeeplApiService.include?(HTTParty)
  end

  test 'should have correct base URI' do
    assert_equal 'https://api-free.deepl.com/v2', DeeplApiService.base_uri
  end

  test 'should respond to translate class method' do
    assert_respond_to DeeplApiService, :translate
  end

  test 'should raise MissingApiKeyError when api key is not configured' do
    prev = ENV['DEEPL_API_KEY']
    begin
      ENV.delete('DEEPL_API_KEY')

      Rails.application.credentials.stub(:dig, nil) do
        error = assert_raises(DeeplApiService::MissingApiKeyError) do
          DeeplApiService.translate('Hello')
        end
        assert_includes error.message, 'DEEPL_API_KEY missing'
      end
    ensure
      ENV['DEEPL_API_KEY'] = prev
    end
  end

  # Translation tests with mocked responses
  test 'should translate text successfully with default parameters' do
    mock_successful_response = mock_deepl_response({
      'translations' => [
        { 'text' => 'Bonjour le monde' },
      ],
    })

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_successful_response) do
        result = DeeplApiService.translate('Hello world')
        assert_equal 'Bonjour le monde', result
      end
    end
  end

  test 'should translate text with custom source and target languages' do
    mock_successful_response = mock_deepl_response({
      'translations' => [
        { 'text' => 'Hola mundo' },
      ],
    })

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_successful_response) do
        result = DeeplApiService.translate('Hello world', to: 'ES', from: 'EN')
        assert_equal 'Hola mundo', result
      end
    end
  end

  test 'should translate text with only target language specified' do
    mock_successful_response = mock_deepl_response({
      'translations' => [
        { 'text' => 'Ciao mondo' },
      ],
    })

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_successful_response) do
        result = DeeplApiService.translate('Hello world', to: 'IT')
        assert_equal 'Ciao mondo', result
      end
    end
  end

  test 'should translate text with only source language specified' do
    mock_successful_response = mock_deepl_response({
      'translations' => [
        { 'text' => 'Bonjour le monde' },
      ],
    })

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_successful_response) do
        result = DeeplApiService.translate('Hello world', from: 'EN')
        assert_equal 'Bonjour le monde', result
      end
    end
  end

  test 'should handle empty text translation' do
    mock_successful_response = mock_deepl_response({
      'translations' => [
        { 'text' => '' },
      ],
    })

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_successful_response) do
        result = DeeplApiService.translate('')
        assert_equal '', result
      end
    end
  end

  test 'should handle long text translation' do
    long_text = 'This is a very long text that needs to be translated. ' * 10
    translated_text = 'Ceci est un texte très long qui doit être traduit. ' * 10

    mock_successful_response = mock_deepl_response({
      'translations' => [
        { 'text' => translated_text },
      ],
    })

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_successful_response) do
        result = DeeplApiService.translate(long_text)
        assert_equal translated_text, result
      end
    end
  end

  test 'should handle text with special characters' do
    special_text = "Hello! @\#$%^&*()_+ world? 123"
    translated_text = "Bonjour! @\#$%^&*()_+ monde? 123"

    mock_successful_response = mock_deepl_response({
      'translations' => [
        { 'text' => translated_text },
      ],
    })

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_successful_response) do
        result = DeeplApiService.translate(special_text)
        assert_equal translated_text, result
      end
    end
  end

  test 'should handle text with HTML entities' do
    html_text = '&lt;p&gt;Hello &amp; welcome&lt;/p&gt;'
    translated_text = '&lt;p&gt;Bonjour &amp; bienvenue&lt;/p&gt;'

    mock_successful_response = mock_deepl_response({
      'translations' => [
        { 'text' => translated_text },
      ],
    })

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_successful_response) do
        result = DeeplApiService.translate(html_text)
        assert_equal translated_text, result
      end
    end
  end

  test 'should handle text with newlines and whitespace' do
    multiline_text = "Hello\nworld\n\nHow are you?"
    translated_text = "Bonjour\nmonde\n\nComment allez-vous?"

    mock_successful_response = mock_deepl_response({
      'translations' => [
        { 'text' => translated_text },
      ],
    })

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_successful_response) do
        result = DeeplApiService.translate(multiline_text)
        assert_equal translated_text, result
      end
    end
  end

  # API request verification tests
  test 'should send correct parameters to DeepL API' do
    captured_params = nil

    mock_post = lambda do |endpoint, options|
      captured_params = { endpoint: endpoint, options: options }
      mock_deepl_response({ 'translations' => [{ 'text' => 'Bonjour' }] })
    end

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_post) do
        DeeplApiService.translate('Hello', to: 'FR', from: 'EN')

        assert_equal '/translate', captured_params[:endpoint]

        body = captured_params[:options][:body]
        assert_equal '9079cde6-1153-4f72-a220-306de587c58e:fx', body[:auth_key]
        assert_equal 'Hello', body[:text]
        assert_equal 'EN', body[:source_lang]
        assert_equal 'FR', body[:target_lang]
      end
    end
  end

  test 'should use default language parameters when not specified' do
    captured_params = nil

    mock_post = lambda do |endpoint, options|
      captured_params = { endpoint: endpoint, options: options }
      mock_deepl_response({ 'translations' => [{ 'text' => 'Bonjour' }] })
    end

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_post) do
        DeeplApiService.translate('Hello')

        body = captured_params[:options][:body]
        assert_equal 'EN', body[:source_lang]
        assert_equal 'FR', body[:target_lang]
      end
    end
  end

  test 'should include auth key in all requests' do
    captured_params = nil

    mock_post = lambda do |endpoint, options|
      captured_params = { endpoint: endpoint, options: options }
      mock_deepl_response({ 'translations' => [{ 'text' => 'Test' }] })
    end

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_post) do
        DeeplApiService.translate('Test text')

        body = captured_params[:options][:body]
        assert_equal '9079cde6-1153-4f72-a220-306de587c58e:fx', body[:auth_key]
      end
    end
  end

  # Error handling tests
  test 'should raise error on API failure with 400 status' do
    mock_error_response = mock_deepl_error_response(400, 'Bad Request')

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_error_response) do
        error = assert_raises(RuntimeError) do
          DeeplApiService.translate('Hello')
        end

        assert_includes error.message, 'DeepL API error: 400'
        assert_includes error.message, 'Bad Request'
      end
    end
  end

  test 'should raise error on API failure with 401 status' do
    mock_error_response = mock_deepl_error_response(401, 'Unauthorized')

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_error_response) do
        error = assert_raises(RuntimeError) do
          DeeplApiService.translate('Hello')
        end

        assert_includes error.message, 'DeepL API error: 401'
        assert_includes error.message, 'Unauthorized'
      end
    end
  end

  test 'should raise error on API failure with 403 status' do
    mock_error_response = mock_deepl_error_response(403, 'Forbidden - Invalid auth key')

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_error_response) do
        error = assert_raises(RuntimeError) do
          DeeplApiService.translate('Hello')
        end

        assert_includes error.message, 'DeepL API error: 403'
        assert_includes error.message, 'Forbidden - Invalid auth key'
      end
    end
  end

  test 'should raise error on API failure with 429 status' do
    mock_error_response = mock_deepl_error_response(429, 'Too Many Requests')

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_error_response) do
        error = assert_raises(RuntimeError) do
          DeeplApiService.translate('Hello')
        end

        assert_includes error.message, 'DeepL API error: 429'
        assert_includes error.message, 'Too Many Requests'
      end
    end
  end

  test 'should raise error on API failure with 500 status' do
    mock_error_response = mock_deepl_error_response(500, 'Internal Server Error')

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_error_response) do
        error = assert_raises(RuntimeError) do
          DeeplApiService.translate('Hello')
        end

        assert_includes error.message, 'DeepL API error: 500'
        assert_includes error.message, 'Internal Server Error'
      end
    end
  end

  test 'should raise error when response has no translations' do
    mock_invalid_response = mock_deepl_response({})

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_invalid_response) do
        error = assert_raises(NoMethodError) do
          DeeplApiService.translate('Hello')
        end

        # This will fail because response['translations'] is nil
        assert_includes error.message, "undefined method `first' for nil"
      end
    end
  end

  test 'should raise error when translations array is empty' do
    mock_empty_response = mock_deepl_response({ 'translations' => [] })

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_empty_response) do
        error = assert_raises(NoMethodError) do
          DeeplApiService.translate('Hello')
        end

        # This will fail because first returns nil
        assert_includes error.message, "undefined method `[]' for nil"
      end
    end
  end

  test 'should raise error when translation object is malformed' do
    mock_malformed_response = mock_deepl_response({
      'translations' => [{}], # Missing 'text' key
    })

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_malformed_response) do
        result = DeeplApiService.translate('Hello')

        # Should return nil when 'text' key is missing
        assert_nil result
      end
    end
  end

  # Language support tests
  test 'should support common European languages' do
    languages = [
      { code: 'DE', expected: 'Hallo Welt' },
      { code: 'ES', expected: 'Hola mundo' },
      { code: 'IT', expected: 'Ciao mondo' },
      { code: 'PT', expected: 'Olá mundo' },
      { code: 'RU', expected: 'Привет мир' },
    ]

    languages.each do |lang|
      mock_response = mock_deepl_response({
        'translations' => [{ 'text' => lang[:expected] }],
      })

      DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
        DeeplApiService.stub(:post, mock_response) do
          result = DeeplApiService.translate('Hello world', to: lang[:code])
          assert_equal lang[:expected], result
        end
      end
    end
  end

  test 'should support Asian languages' do
    languages = [
      { code: 'JA', expected: 'こんにちは世界' },
      { code: 'ZH', expected: '你好世界' },
      { code: 'KO', expected: '안녕하세요 세계' },
    ]

    languages.each do |lang|
      mock_response = mock_deepl_response({
        'translations' => [{ 'text' => lang[:expected] }],
      })

      DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
        DeeplApiService.stub(:post, mock_response) do
          result = DeeplApiService.translate('Hello world', to: lang[:code])
          assert_equal lang[:expected], result
        end
      end
    end
  end

  # Edge case tests
  test 'should handle network timeout gracefully' do
    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, ->(*_args) { raise Timeout::Error, 'Timeout' }) do
        error = assert_raises(Timeout::Error) do
          DeeplApiService.translate('Hello')
        end

        assert_equal 'Timeout', error.message
      end
    end
  end

  test 'should handle connection refused gracefully' do
    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, ->(*_args) { raise Errno::ECONNREFUSED }) do
        error = assert_raises(Errno::ECONNREFUSED) do
          DeeplApiService.translate('Hello')
        end

        assert_includes error.message, 'Connection refused'
      end
    end
  end

  test 'should handle SSL certificate errors gracefully' do
    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, ->(*_args) { raise OpenSSL::SSL::SSLError }) do
        error = assert_raises(OpenSSL::SSL::SSLError) do
          DeeplApiService.translate('Hello')
        end

        assert_includes error.message, 'SSL'
      end
    end
  end

  test 'should handle JSON parsing errors gracefully' do
    mock_invalid_json_response = Object.new
    mock_invalid_json_response.define_singleton_method(:success?) { true }
    mock_invalid_json_response.define_singleton_method(:parsed_response) do
      raise JSON::ParserError, 'Invalid JSON'
    end

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_invalid_json_response) do
        error = assert_raises(JSON::ParserError) do
          DeeplApiService.translate('Hello')
        end

        assert_equal 'Invalid JSON', error.message
      end
    end
  end

  # Performance and usage tests
  test 'should handle multiple consecutive translations' do
    translations = [
      { text: 'Hello', expected: 'Bonjour' },
      { text: 'World', expected: 'Monde' },
      { text: 'Goodbye', expected: 'Au revoir' },
    ]

    translations.each do |translation|
      mock_response = mock_deepl_response({
        'translations' => [{ 'text' => translation[:expected] }],
      })

      DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
        DeeplApiService.stub(:post, mock_response) do
          result = DeeplApiService.translate(translation[:text])
          assert_equal translation[:expected], result
        end
      end
    end
  end

  test 'should handle concurrent translation requests' do
    # Simulate concurrent requests by testing thread safety
    mock_response = mock_deepl_response({
      'translations' => [{ 'text' => 'Bonjour' }],
    })

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_response) do
        threads = Array.new(3) do |i|
          Thread.new do
            result = DeeplApiService.translate("Hello #{i}")
            assert_equal 'Bonjour', result
          end
        end

        threads.each(&:join)
      end
    end
  end

  test 'should preserve text formatting in translations' do
    formatted_text = '**Bold** and *italic* text with [links](http://example.com)'
    translated_text = '**Gras** et *italique* texte avec [liens](http://example.com)'

    mock_response = mock_deepl_response({
      'translations' => [{ 'text' => translated_text }],
    })

    DeeplApiService.stub(:api_key, DeeplApiService::TEST_API_KEY) do
      DeeplApiService.stub(:post, mock_response) do
        result = DeeplApiService.translate(formatted_text)
        assert_equal translated_text, result
      end
    end
  end

  private

  def mock_deepl_response(parsed_response)
    mock_response = Object.new
    mock_response.define_singleton_method(:success?) { true }
    mock_response.define_singleton_method(:parsed_response) { parsed_response }
    mock_response
  end

  def mock_deepl_error_response(status_code, body)
    mock_response = Object.new
    mock_response.define_singleton_method(:success?) { false }
    mock_response.define_singleton_method(:code) { status_code }
    mock_response.define_singleton_method(:body) { body }
    mock_response
  end
end
