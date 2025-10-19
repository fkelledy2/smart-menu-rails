require 'test_helper'

class CdnAnalyticsServiceTest < ActiveSupport::TestCase
  setup do
    @service = CdnAnalyticsService.instance
    @original_asset_host = Rails.application.config.asset_host
  end

  teardown do
    Rails.application.config.asset_host = @original_asset_host
  end

  test 'service is a singleton' do
    service1 = CdnAnalyticsService.instance
    service2 = CdnAnalyticsService.instance
    
    assert_same service1, service2
  end

  test 'fetch_analytics returns hash with expected keys' do
    analytics = @service.fetch_analytics
    
    assert analytics.key?(:requests)
    assert analytics.key?(:cached_requests)
    assert analytics.key?(:bandwidth)
    assert analytics.key?(:cached_bandwidth)
    assert analytics.key?(:average_response_time)
  end

  test 'fetch_analytics accepts date range parameters' do
    start_date = 30.days.ago
    end_date = Time.current
    
    analytics = @service.fetch_analytics(start_date: start_date, end_date: end_date)
    
    assert_not_nil analytics
    assert analytics.key?(:requests)
  end

  test 'cache_hit_rate calculates percentage correctly' do
    hit_rate = @service.cache_hit_rate
    
    assert hit_rate.is_a?(Float)
    assert_operator hit_rate, :>=, 0
    assert_operator hit_rate, :<=, 100
  end

  test 'cache_hit_rate returns 0 when no requests' do
    @service.stub(:fetch_analytics, { requests: 0, cached_requests: 0 }) do
      assert_equal 0.0, @service.cache_hit_rate
    end
  end

  test 'cache_hit_rate calculates correct percentage' do
    @service.stub(:fetch_analytics, { requests: 100, cached_requests: 85 }) do
      assert_equal 85.0, @service.cache_hit_rate
    end
  end

  test 'bandwidth_saved calculates percentage correctly' do
    bandwidth_saved = @service.bandwidth_saved
    
    assert bandwidth_saved.is_a?(Float)
    assert_operator bandwidth_saved, :>=, 0
    assert_operator bandwidth_saved, :<=, 100
  end

  test 'bandwidth_saved returns 0 when no bandwidth' do
    @service.stub(:fetch_analytics, { bandwidth: 0, cached_bandwidth: 0 }) do
      assert_equal 0.0, @service.bandwidth_saved
    end
  end

  test 'bandwidth_saved calculates correct percentage' do
    @service.stub(:fetch_analytics, { bandwidth: 1000, cached_bandwidth: 850 }) do
      assert_equal 85.0, @service.bandwidth_saved
    end
  end

  test 'performance_summary returns complete metrics' do
    summary = @service.performance_summary
    
    assert summary.key?(:cache_hit_rate)
    assert summary.key?(:bandwidth_saved)
    assert summary.key?(:total_requests)
    assert summary.key?(:cached_requests)
    assert summary.key?(:bandwidth_mb)
    assert summary.key?(:cached_bandwidth_mb)
    assert summary.key?(:average_response_time)
  end

  test 'performance_summary converts bandwidth to MB' do
    summary = @service.performance_summary
    
    assert summary[:bandwidth_mb].is_a?(Float)
    assert summary[:cached_bandwidth_mb].is_a?(Float)
    assert_operator summary[:bandwidth_mb], :>, 0
  end

  test 'health_check returns status hash' do
    Rails.application.config.asset_host = 'https://cdn.example.com'
    
    health = @service.health_check
    
    assert health.key?(:status)
    assert health.key?(:cache_hit_rate)
    assert health.key?(:asset_host)
    assert health.key?(:cdn_enabled)
    assert health.key?(:provider)
    assert health.key?(:last_check)
  end

  test 'health_check shows disabled when no asset_host' do
    Rails.application.config.asset_host = nil
    
    health = @service.health_check
    
    assert_equal 'disabled', health[:status]
    assert_not health[:cdn_enabled]
  end

  test 'health_check shows cdn_enabled when asset_host configured' do
    Rails.application.config.asset_host = 'https://cdn.example.com'
    
    health = @service.health_check
    
    assert health[:cdn_enabled]
    assert_equal 'https://cdn.example.com', health[:asset_host]
  end

  test 'health_check includes provider information' do
    Rails.application.config.asset_host = 'https://cdn.cloudflare.com'
    
    health = @service.health_check
    
    assert_equal 'cloudflare', health[:provider]
  end

  test 'health_check includes timestamp' do
    health = @service.health_check
    
    assert health[:last_check].is_a?(Time)
    assert_in_delta Time.current.to_i, health[:last_check].to_i, 5
  end

  test 'class methods delegate to instance' do
    analytics = CdnAnalyticsService.fetch_analytics
    assert_not_nil analytics
    
    hit_rate = CdnAnalyticsService.cache_hit_rate
    assert hit_rate.is_a?(Float)
    
    bandwidth = CdnAnalyticsService.bandwidth_saved
    assert bandwidth.is_a?(Float)
  end

  test 'handles errors gracefully in fetch_analytics' do
    # Force an error in the private method
    @service.stub(:mock_analytics, -> { raise StandardError, 'API Error' }) do
      # Should return empty analytics on error
      analytics = @service.fetch_analytics
      assert_not_nil analytics
      assert_equal 0, analytics[:requests]
    end
  end

  test 'handles errors gracefully in health_check' do
    Rails.application.config.asset_host = 'https://invalid-cdn.example.com'
    
    # Should not raise error even if CDN is unreachable
    assert_nothing_raised do
      health = @service.health_check
      assert_not_nil health
    end
  end

  test 'cdn_provider detection for cloudflare' do
    Rails.application.config.asset_host = 'https://cdn.cloudflare.com'
    
    health = @service.health_check
    
    assert_equal 'cloudflare', health[:provider]
  end

  test 'cdn_provider detection for cloudfront' do
    Rails.application.config.asset_host = 'https://d123.cloudfront.net'
    
    health = @service.health_check
    
    assert_equal 'cloudfront', health[:provider]
  end

  test 'cdn_provider detection for custom CDN' do
    Rails.application.config.asset_host = 'https://custom-cdn.example.com'
    
    health = @service.health_check
    
    assert_equal 'custom', health[:provider]
  end

  test 'cdn_provider returns none when CDN disabled' do
    Rails.application.config.asset_host = nil
    
    health = @service.health_check
    
    assert_equal 'none', health[:provider]
  end

  test 'mock_analytics returns realistic data' do
    analytics = @service.send(:mock_analytics)
    
    assert_operator analytics[:requests], :>, 0
    assert_operator analytics[:cached_requests], :>, 0
    assert_operator analytics[:bandwidth], :>, 0
    assert_operator analytics[:cached_bandwidth], :>, 0
    assert_operator analytics[:average_response_time], :>, 0
    
    # Cached should be less than total
    assert_operator analytics[:cached_requests], :<=, analytics[:requests]
    assert_operator analytics[:cached_bandwidth], :<=, analytics[:bandwidth]
  end

  test 'performance_summary calculates metrics correctly' do
    # Use known mock data
    mock_data = {
      requests: 1000,
      cached_requests: 850,
      bandwidth: 100_000_000, # 100 MB
      cached_bandwidth: 85_000_000, # 85 MB
      average_response_time: 50,
    }
    
    @service.stub(:fetch_analytics, mock_data) do
      summary = @service.performance_summary
      
      assert_equal 85.0, summary[:cache_hit_rate]
      assert_equal 85.0, summary[:bandwidth_saved]
      assert_equal 1000, summary[:total_requests]
      assert_equal 850, summary[:cached_requests]
      assert_in_delta 95.37, summary[:bandwidth_mb], 0.1
      assert_in_delta 81.06, summary[:cached_bandwidth_mb], 0.1
      assert_equal 50, summary[:average_response_time]
    end
  end

  test 'respects CDN_HOST environment variable' do
    original_env = ENV['CDN_HOST']
    Rails.application.config.asset_host = nil
    ENV['CDN_HOST'] = 'https://env-cdn.example.com'
    
    health = @service.health_check
    
    assert health[:cdn_enabled]
    assert_equal 'https://env-cdn.example.com', health[:asset_host]
    
    ENV['CDN_HOST'] = original_env
  end
end
