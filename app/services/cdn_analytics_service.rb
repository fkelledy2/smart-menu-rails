# frozen_string_literal: true

# Service for tracking and analyzing CDN performance metrics
class CdnAnalyticsService
  include Singleton

  class << self
    delegate :fetch_analytics, :cache_hit_rate, :bandwidth_saved, to: :instance
  end

  # Fetch CDN analytics for a date range
  # @param start_date [Time] Start date for analytics
  # @param end_date [Time] End date for analytics
  # @return [Hash] Analytics data
  def fetch_analytics(start_date: 7.days.ago, end_date: Time.current)
    Rails.logger.info "[CDN Analytics] Fetching analytics from #{start_date} to #{end_date}"

    # In production, this would fetch from Cloudflare API
    # For now, return mock data
    mock_analytics
  rescue StandardError => e
    Rails.logger.error "[CDN Analytics] Error fetching analytics: #{e.message}"
    # Return empty analytics on error
    {
      requests: 0,
      cached_requests: 0,
      bandwidth: 0,
      cached_bandwidth: 0,
      average_response_time: 0,
      uncached_requests: 0,
      errors: 0,
    }
  end

  # Calculate cache hit rate
  # @return [Float] Hit rate percentage
  def cache_hit_rate
    analytics = fetch_analytics
    total = analytics[:requests]
    cached = analytics[:cached_requests]

    return 0.0 if total.zero?

    (cached.to_f / total * 100).round(2)
  end

  # Calculate bandwidth saved by CDN
  # @return [Float] Bandwidth saved percentage
  def bandwidth_saved
    analytics = fetch_analytics
    total_bandwidth = analytics[:bandwidth]
    cached_bandwidth = analytics[:cached_bandwidth]

    return 0.0 if total_bandwidth.zero?

    (cached_bandwidth.to_f / total_bandwidth * 100).round(2)
  end

  # Get CDN performance summary
  # @return [Hash] Performance summary
  def performance_summary
    analytics = fetch_analytics

    {
      cache_hit_rate: cache_hit_rate,
      bandwidth_saved: bandwidth_saved,
      total_requests: analytics[:requests],
      cached_requests: analytics[:cached_requests],
      bandwidth_mb: (analytics[:bandwidth] / 1_048_576.0).round(2),
      cached_bandwidth_mb: (analytics[:cached_bandwidth] / 1_048_576.0).round(2),
      average_response_time: analytics[:average_response_time],
    }
  end

  # Check CDN health status
  # @return [Hash] Health status
  def health_check
    {
      status: check_cdn_status,
      cache_hit_rate: cache_hit_rate,
      asset_host: asset_host,
      cdn_enabled: cdn_enabled?,
      provider: cdn_provider,
      last_check: Time.current,
    }
  end

  private

  # Check if CDN is enabled
  # @return [Boolean]
  def cdn_enabled?
    asset_host.present?
  end

  # Get asset host from Rails configuration
  # @return [String, nil] Asset host URL
  def asset_host
    Rails.application.config.asset_host || ENV.fetch('CDN_HOST', nil)
  end

  # Get CDN provider name
  # @return [String] Provider name
  def cdn_provider
    return 'none' unless cdn_enabled?

    host = asset_host.to_s.downcase
    if host.include?('cloudflare')
      'cloudflare'
    elsif host.include?('cloudfront')
      'cloudfront'
    else
      'custom'
    end
  end

  # Check CDN connectivity status
  # @return [String] Status (healthy, degraded, unhealthy)
  def check_cdn_status
    return 'disabled' unless cdn_enabled?

    # Test CDN connectivity by checking if assets are accessible
    test_url = "#{asset_host}/assets/application.css"

    uri = URI(test_url)
    response = Net::HTTP.get_response(uri)

    case response.code
    when '200'
      'healthy'
    when '404'
      'degraded'
    else
      'unhealthy'
    end
  rescue StandardError => e
    Rails.logger.error "[CDN Analytics] Error checking CDN status: #{e.message}"
    'unhealthy'
  end

  # Generate mock analytics data for testing
  # @return [Hash] Mock analytics data
  def mock_analytics
    {
      requests: 100_000,
      cached_requests: 85_000,
      bandwidth: 500_000_000, # 500 MB
      cached_bandwidth: 425_000_000, # 425 MB (85%)
      average_response_time: 45, # milliseconds
      uncached_requests: 15_000,
      errors: 100,
    }
  end
end
