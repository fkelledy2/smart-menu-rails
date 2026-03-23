# frozen_string_literal: true

require 'test_helper'

class GooglePlaces::PlaceDetailsTest < ActiveSupport::TestCase
  def service
    GooglePlaces::PlaceDetails.new(api_key: 'fake-key-for-tests')
  end

  # =========================================================================
  # validate_config! — raises without api_key
  # =========================================================================

  test 'raises ConfigurationError when api_key is blank' do
    assert_raises(ExternalApiClient::ConfigurationError) do
      GooglePlaces::PlaceDetails.new(api_key: '')
    end
  end

  test 'raises ArgumentError when place_id is blank' do
    # We stub the HTTP call to prevent real network requests
    stub_resp = Object.new
    stub_resp.define_singleton_method(:parsed_response) { { 'result' => {} } }

    GooglePlaces::PlaceDetails.stub(:get, stub_resp) do
      assert_raises(ArgumentError, /place_id required/) do
        service.fetch!('')
      end
    end
  end

  # =========================================================================
  # fetch! — with stubbed HTTP response
  # =========================================================================

  test 'returns parsed place attributes from API response' do
    result_body = {
      'result' => {
        'place_id' => 'ChIJ-abc123',
        'name' => 'Test Bistro',
        'website' => 'https://testbistro.com',
        'url' => 'https://maps.google.com/?cid=123',
        'types' => %w[restaurant food],
        'formatted_address' => '1 Main St, Dublin',
        'geometry' => { 'location' => { 'lat' => 53.3, 'lng' => -6.2 } },
        'opening_hours' => nil,
      },
    }

    stub_resp = Object.new
    stub_resp.define_singleton_method(:parsed_response) { result_body }

    svc = service
    svc.stub(:get, stub_resp) do
      result = svc.fetch!('ChIJ-abc123')

      assert_equal 'ChIJ-abc123', result[:place_id]
      assert_equal 'Test Bistro', result[:name]
      assert_equal 'https://testbistro.com', result[:website]
      assert_equal %w[restaurant food], result[:types]
      assert_in_delta 53.3, result[:location][:lat], 0.001
      assert_nil result[:opening_hours]
    end
  end

  # =========================================================================
  # parse_opening_hours — pure logic (accessed via fetch!)
  # =========================================================================

  test 'returns nil for nil opening_hours' do
    result_body = { 'result' => { 'opening_hours' => nil } }
    stub_resp = Object.new
    stub_resp.define_singleton_method(:parsed_response) { result_body }

    svc = service
    svc.stub(:get, stub_resp) do
      result = svc.fetch!('ChIJtest')
      assert_nil result[:opening_hours]
    end
  end

  test 'returns 24/7 hours for single period with no close' do
    opening_hours = { 'periods' => [{ 'open' => { 'day' => 0, 'time' => '0000' }, 'close' => nil }] }
    result_body = { 'result' => { 'opening_hours' => opening_hours } }
    stub_resp = Object.new
    stub_resp.define_singleton_method(:parsed_response) { result_body }

    svc = service
    svc.stub(:get, stub_resp) do
      result = svc.fetch!('ChIJtest')
      hours = result[:opening_hours]
      assert_equal 7, hours.length
      hours.each do |h|
        assert_equal 0, h['open_hour']
        assert_equal 23, h['close_hour']
      end
    end
  end

  test 'parses regular opening periods correctly' do
    periods = [
      { 'open' => { 'day' => 1, 'time' => '0900' }, 'close' => { 'day' => 1, 'time' => '2100' } },
      { 'open' => { 'day' => 2, 'time' => '1000' }, 'close' => { 'day' => 2, 'time' => '2200' } },
    ]
    opening_hours = { 'periods' => periods }
    result_body = { 'result' => { 'opening_hours' => opening_hours } }
    stub_resp = Object.new
    stub_resp.define_singleton_method(:parsed_response) { result_body }

    svc = service
    svc.stub(:get, stub_resp) do
      result = svc.fetch!('ChIJtest')
      hours = result[:opening_hours]
      assert_equal 2, hours.length

      monday = hours.first
      assert_equal 1, monday['day']
      assert_equal 9, monday['open_hour']
      assert_equal 0, monday['open_min']
      assert_equal 21, monday['close_hour']
    end
  end

  test 'skips periods with short/missing open time' do
    periods = [
      { 'open' => { 'day' => 1, 'time' => '09' }, 'close' => { 'day' => 1, 'time' => '2100' } },
      { 'open' => { 'day' => 2, 'time' => '1000' }, 'close' => { 'day' => 2, 'time' => '2200' } },
    ]
    opening_hours = { 'periods' => periods }
    result_body = { 'result' => { 'opening_hours' => opening_hours } }
    stub_resp = Object.new
    stub_resp.define_singleton_method(:parsed_response) { result_body }

    svc = service
    svc.stub(:get, stub_resp) do
      result = svc.fetch!('ChIJtest')
      assert_equal 1, result[:opening_hours].length
    end
  end
end
