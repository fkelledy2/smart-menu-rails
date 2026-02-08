require 'test_helper'

class ExternalApiClientTest < ActiveSupport::TestCase
  setup do
    @client = ExternalApiClient.new(base_uri: 'https://api.example.com')
  end

  test 'initializes with default configuration' do
    assert_not_nil @client.config
    assert_equal ExternalApiClient::DEFAULT_TIMEOUT, @client.config[:timeout]
    assert_equal ExternalApiClient::DEFAULT_RETRIES, @client.config[:max_retries]
  end

  test 'merges custom configuration with defaults' do
    client = ExternalApiClient.new(
      base_uri: 'https://api.example.com',
      timeout: 60.seconds,
      max_retries: 5,
    )

    assert_equal 60.seconds, client.config[:timeout]
    assert_equal 5, client.config[:max_retries]
  end

  test 'raises error when base_uri is missing' do
    assert_raises(ExternalApiClient::ConfigurationError) do
      ExternalApiClient.new
    end
  end

  test 'default config includes expected keys' do
    config = @client.send(:default_config)

    assert_includes config.keys, :timeout
    assert_includes config.keys, :max_retries
    assert_includes config.keys, :retry_delay
    assert_includes config.keys, :backoff_multiplier
    assert_includes config.keys, :base_uri
    assert_includes config.keys, :headers
  end

  test 'retryable errors include network errors' do
    errors = @client.send(:retryable_errors)

    assert_includes errors, Net::ReadTimeout
    assert_includes errors, Net::OpenTimeout
    assert_includes errors, Errno::ECONNREFUSED
    assert_includes errors, SocketError
  end

  test 'handles successful response' do
    response = OpenStruct.new(code: 200, body: 'OK', success?: true)

    result = @client.send(:handle_response, response)
    assert_equal response, result
  end

  test 'raises authentication error for 401' do
    response = OpenStruct.new(code: 401, body: 'Unauthorized')

    assert_raises(ExternalApiClient::AuthenticationError) do
      @client.send(:handle_response, response)
    end
  end

  test 'raises authentication error for 403' do
    response = OpenStruct.new(code: 403, body: 'Forbidden')

    assert_raises(ExternalApiClient::AuthenticationError) do
      @client.send(:handle_response, response)
    end
  end

  test 'raises rate limit error for 429' do
    response = OpenStruct.new(code: 429, body: 'Too Many Requests')

    assert_raises(ExternalApiClient::RateLimitError) do
      @client.send(:handle_response, response)
    end
  end

  test 'raises API error for 4xx client errors' do
    response = OpenStruct.new(code: 400, body: 'Bad Request')

    assert_raises(ExternalApiClient::ApiError) do
      @client.send(:handle_response, response)
    end
  end

  test 'raises API error for 5xx server errors' do
    response = OpenStruct.new(code: 500, body: 'Internal Server Error')

    assert_raises(ExternalApiClient::ApiError) do
      @client.send(:handle_response, response)
    end
  end

  test 'handles 2xx success codes' do
    [200, 201, 204].each do |code|
      response = OpenStruct.new(code: code, body: 'Success')

      assert_nothing_raised do
        @client.send(:handle_response, response)
      end
    end
  end

  test 'validates configuration on initialization' do
    assert_nothing_raised do
      ExternalApiClient.new(base_uri: 'https://api.example.com')
    end
  end

  test 'healthy? returns true when health check endpoint not configured' do
    client = ExternalApiClient.new(base_uri: 'https://api.example.com')
    assert client.healthy?
  end

  test 'has correct default timeout' do
    assert_equal 30.seconds, ExternalApiClient::DEFAULT_TIMEOUT
  end

  test 'has correct default retries' do
    assert_equal 3, ExternalApiClient::DEFAULT_RETRIES
  end

  test 'has correct default retry delay' do
    assert_equal 1.second, ExternalApiClient::DEFAULT_RETRY_DELAY
  end

  test 'has correct default backoff multiplier' do
    assert_equal 2, ExternalApiClient::DEFAULT_BACKOFF_MULTIPLIER
  end
end
