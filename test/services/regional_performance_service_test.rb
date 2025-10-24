# frozen_string_literal: true

require 'test_helper'

class RegionalPerformanceServiceTest < ActiveSupport::TestCase
  setup do
    @service = RegionalPerformanceService.instance
    @request = Minitest::Mock.new
    Rails.cache.clear
  end

  test 'singleton pattern works' do
    assert_equal @service, RegionalPerformanceService.instance
    assert_respond_to RegionalPerformanceService, :track_latency
  end

  test 'track_latency stores metrics' do
    @request.expect :headers, { 'CF-IPCountry' => 'US' }
    @request.expect :remote_ip, '1.2.3.4'
    @request.expect :path, '/test'
    @request.expect :method, 'GET'
    
    result = @service.track_latency(@request, 100.5)
    
    assert result
    @request.verify
  end

  test 'metrics_for_region returns empty metrics when no data' do
    metrics = @service.metrics_for_region('us', period: '24h')
    
    assert_equal 0, metrics[:request_count]
    assert_equal 0.0, metrics[:avg]
    assert_equal 0.0, metrics[:p95]
  end

  test 'metrics_for_region calculates correct metrics' do
    # Track some latencies
    @request.expect :headers, { 'CF-IPCountry' => 'US' }
    @request.expect :remote_ip, '1.2.3.4'
    @request.expect :path, '/test'
    @request.expect :method, 'GET'
    
    @service.track_latency(@request, 100)
    
    @request.expect :headers, { 'CF-IPCountry' => 'US' }
    @request.expect :remote_ip, '1.2.3.4'
    @request.expect :path, '/test'
    @request.expect :method, 'GET'
    
    @service.track_latency(@request, 200)
    
    metrics = @service.metrics_for_region('us', period: '24h')
    
    assert_equal 2, metrics[:request_count]
    assert_operator metrics[:avg], :>, 0
    assert_operator metrics[:p95], :>, 0
    
    @request.verify
  end

  test 'slowest_regions returns regions sorted by p95' do
    regions = @service.slowest_regions(limit: 3, period: '24h')
    
    assert_kind_of Array, regions
    assert_operator regions.size, :<=, 3
  end

  test 'all_regions_summary returns metrics for all regions' do
    summary = @service.all_regions_summary(period: '24h')
    
    assert_kind_of Hash, summary
    assert_includes summary.keys, 'us'
    assert_includes summary.keys, 'eu'
  end

  test 'region_slow? returns false for good performance' do
    result = @service.region_slow?('us', threshold_ms: 1000)
    
    refute result
  end

  test 'recommendations_for_region returns recommendations' do
    recommendations = @service.recommendations_for_region('us')
    
    assert_kind_of Array, recommendations
    refute_empty recommendations
  end

  test 'class methods delegate to instance' do
    assert_respond_to RegionalPerformanceService, :track_latency
    assert_respond_to RegionalPerformanceService, :metrics_for_region
    assert_respond_to RegionalPerformanceService, :slowest_regions
  end
end
