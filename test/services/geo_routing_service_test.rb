# frozen_string_literal: true

require 'test_helper'

class GeoRoutingServiceTest < ActiveSupport::TestCase
  setup do
    @service = GeoRoutingService.instance
  end

  test 'singleton pattern works' do
    assert_equal @service, GeoRoutingService.instance
    assert_respond_to GeoRoutingService, :detect_location
  end

  test 'detect_location with CloudFlare header' do
    request = OpenStruct.new(
      headers: { 'CF-IPCountry' => 'GB' },
      remote_ip: '1.2.3.4',
    )

    location = @service.detect_location(request)

    assert_equal 'GB', location[:country]
    assert_equal 'EU', location[:continent]
    assert_equal 'eu', location[:region]
    assert_equal '1.2.3.4', location[:ip]
  end

  test 'detect_location defaults to US for local IP' do
    request = OpenStruct.new(
      headers: {},
      remote_ip: '127.0.0.1',
    )

    location = @service.detect_location(request)

    assert_equal 'US', location[:country]
    assert_equal 'NA', location[:continent]
    assert_equal 'us', location[:region]
  end

  test 'optimal_edge_location returns correct edge for US' do
    location = { region: 'us' }

    edge = @service.optimal_edge_location(location)

    assert_match(/cdn/, edge)
  end

  test 'supported_regions returns all regions' do
    regions = @service.supported_regions

    assert_kind_of Array, regions
    assert_includes regions, 'us'
    assert_includes regions, 'eu'
    assert_includes regions, 'asia'
  end

  test 'region_stats returns correct structure' do
    stats = @service.region_stats

    assert_kind_of Hash, stats
    assert_includes stats, :supported_regions
    assert_includes stats, :edge_locations
    assert_includes stats, :cdn_enabled
  end

  test 'class methods delegate to instance' do
    assert_respond_to GeoRoutingService, :detect_location
    assert_respond_to GeoRoutingService, :optimal_edge_location
    assert_respond_to GeoRoutingService, :asset_url_for_location
  end
end
