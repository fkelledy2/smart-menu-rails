# frozen_string_literal: true

require 'test_helper'

class CityDiscoveryJobTest < ActiveSupport::TestCase
  test 'does nothing when city_query is blank' do
    called = false

    GooglePlaces::CityDiscovery.stub(:new, lambda {
      called = true
      nil
    },) do
      CityDiscoveryJob.new.perform(city_query: '', place_types: ['restaurant'])
    end

    assert_equal false, called
  end

  test 'does nothing when city_query is whitespace only' do
    called = false

    GooglePlaces::CityDiscovery.stub(:new, lambda {
      called = true
      nil
    },) do
      CityDiscoveryJob.new.perform(city_query: '   ', place_types: [])
    end

    assert_equal false, called
  end

  test 'raises when Google Maps API key is missing' do
    original_key = ENV.fetch('GOOGLE_MAPS_API_KEY', nil)
    original_browser_key = ENV.fetch('GOOGLE_MAPS_BROWSER_API_KEY', nil)

    ENV.delete('GOOGLE_MAPS_API_KEY')
    ENV.delete('GOOGLE_MAPS_BROWSER_API_KEY')

    # Stub credentials to return nil too
    Rails.application.credentials.stub(:google_maps_api_key, nil) do
      assert_raises(RuntimeError, /Google Places API key/) do
        CityDiscoveryJob.new.perform(city_query: 'Dublin', place_types: ['restaurant'])
      end
    end
  ensure
    ENV['GOOGLE_MAPS_API_KEY'] = original_key if original_key
    ENV['GOOGLE_MAPS_BROWSER_API_KEY'] = original_browser_key if original_browser_key
  end

  test 'calls GooglePlaces::CityDiscovery.discover! when API key is present' do
    discover_called = false
    fake_client = Object.new
    fake_client.define_singleton_method(:discover!) { |**_kwargs| discover_called = true }

    ENV['GOOGLE_MAPS_API_KEY'] = 'test-key-for-test'
    GooglePlaces::CityDiscovery.stub(:new, ->(**_kwargs) { fake_client }) do
      CityDiscoveryJob.new.perform(city_query: 'Dublin', place_types: ['restaurant'])
    end

    assert discover_called
  ensure
    ENV.delete('GOOGLE_MAPS_API_KEY')
  end

  test 'enqueues asynchronously without raising' do
    assert_nothing_raised do
      CityDiscoveryJob.perform_later(city_query: 'test', place_types: [])
    end
  end
end
