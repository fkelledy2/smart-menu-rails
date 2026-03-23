require 'test_helper'

class WhiskyHunterClientTest < ActiveSupport::TestCase
  def client_with_base_uri
    ClimateControl.modify(WHISKY_HUNTER_BASE_URI: 'https://api.whiskyhunter.net') do
      WhiskyHunterClient.new
    end rescue WhiskyHunterClient.new(base_uri: 'https://api.whiskyhunter.net')
  end

  test 'inherits from ExternalApiClient' do
    assert WhiskyHunterClient < ExternalApiClient
  end

  test 'raises ConfigurationError when base_uri env var is absent' do
    original = ENV.delete('WHISKY_HUNTER_BASE_URI')
    assert_raises(ExternalApiClient::ConfigurationError) { WhiskyHunterClient.new }
  ensure
    ENV['WHISKY_HUNTER_BASE_URI'] = original if original
  end

  test 'search_by_name raises ArgumentError for empty string' do
    ENV['WHISKY_HUNTER_BASE_URI'] = 'https://api.whiskyhunter.net'
    client = WhiskyHunterClient.new
    assert_raises(ArgumentError) { client.search_by_name('') }
  ensure
    ENV.delete('WHISKY_HUNTER_BASE_URI')
  end

  test 'search_by_name raises ArgumentError for whitespace-only name' do
    ENV['WHISKY_HUNTER_BASE_URI'] = 'https://api.whiskyhunter.net'
    client = WhiskyHunterClient.new
    assert_raises(ArgumentError) { client.search_by_name('   ') }
  ensure
    ENV.delete('WHISKY_HUNTER_BASE_URI')
  end

  test 'search_by_name raises ArgumentError for nil' do
    ENV['WHISKY_HUNTER_BASE_URI'] = 'https://api.whiskyhunter.net'
    client = WhiskyHunterClient.new
    assert_raises(ArgumentError) { client.search_by_name(nil) }
  ensure
    ENV.delete('WHISKY_HUNTER_BASE_URI')
  end

  test 'default_config includes base_uri, api_key, timeout, max_retries' do
    ENV['WHISKY_HUNTER_BASE_URI'] = 'https://api.whiskyhunter.net'
    client = WhiskyHunterClient.new
    config = client.send(:default_config)
    assert config.key?(:base_uri)
    assert config.key?(:api_key)
    assert config.key?(:timeout)
    assert config.key?(:max_retries)
    assert_equal 2, config[:max_retries]
    assert_equal 30.seconds, config[:timeout]
  ensure
    ENV.delete('WHISKY_HUNTER_BASE_URI')
  end
end
