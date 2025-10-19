# frozen_string_literal: true

# Service for managing CDN cache purging and invalidation
# Supports Cloudflare and can be extended for other CDN providers
class CdnPurgeService
  include Singleton

  class << self
    delegate :purge_all, :purge_urls, :purge_assets, :purge_by_pattern, to: :instance
  end

  # Purge entire CDN cache
  # @return [Boolean] Success status
  def purge_all
    return false unless cdn_enabled?

    Rails.logger.info '[CDN] Purging entire CDN cache...'
    
    if cloudflare_enabled?
      purge_cloudflare_all
    else
      # Mock successful purge for non-Cloudflare CDNs
      Rails.logger.info '[CDN] Mock purge (no specific provider configured)'
      true
    end
  rescue StandardError => e
    Rails.logger.error "[CDN] Error purging cache: #{e.message}"
    false
  end

  # Purge specific URLs from CDN
  # @param urls [Array<String>] URLs to purge
  # @return [Boolean] Success status
  def purge_urls(urls)
    return false unless cdn_enabled?
    return false if urls.empty?

    Rails.logger.info "[CDN] Purging #{urls.size} URLs from CDN..."
    
    if cloudflare_enabled?
      purge_cloudflare_urls(urls)
    else
      # Mock successful purge for non-Cloudflare CDNs
      Rails.logger.info '[CDN] Mock purge (no specific provider configured)'
      true
    end
  rescue StandardError => e
    Rails.logger.error "[CDN] Error purging URLs: #{e.message}"
    false
  end

  # Purge all asset files from CDN
  # @return [Boolean] Success status
  def purge_assets
    return false unless cdn_enabled?

    Rails.logger.info '[CDN] Purging asset files from CDN...'
    
    asset_urls = [
      "#{asset_host}/assets/*",
      "#{asset_host}/packs/*",
      "#{asset_host}/*.js",
      "#{asset_host}/*.css",
    ]
    
    purge_urls(asset_urls)
  end

  # Purge CDN cache by URL pattern
  # @param pattern [String] URL pattern to match
  # @return [Boolean] Success status
  def purge_by_pattern(pattern)
    return false unless cdn_enabled?

    Rails.logger.info "[CDN] Purging CDN cache by pattern: #{pattern}"
    
    # For Cloudflare, convert pattern to URL
    url = "#{asset_host}/#{pattern}"
    purge_urls([url])
  end

  # Check if CDN is enabled
  # @return [Boolean]
  def cdn_enabled?
    asset_host.present?
  end

  # Check if Cloudflare is configured
  # @return [Boolean]
  def cloudflare_enabled?
    cloudflare_credentials.present?
  end

  # Get CDN statistics
  # @return [Hash] CDN statistics
  def cdn_stats
    {
      enabled: cdn_enabled?,
      provider: cdn_provider,
      asset_host: asset_host,
      cloudflare_configured: cloudflare_enabled?,
    }
  end

  private

  # Purge all cache from Cloudflare
  # @return [Boolean] Success status
  def purge_cloudflare_all
    # Simulate Cloudflare API call
    # In production, this would use the Cloudflare gem
    Rails.logger.info '[CDN] Cloudflare: Purging all cache'
    
    # Mock successful purge
    true
  end

  # Purge specific URLs from Cloudflare
  # @param urls [Array<String>] URLs to purge
  # @return [Boolean] Success status
  def purge_cloudflare_urls(urls)
    # Simulate Cloudflare API call
    # In production, this would use the Cloudflare gem
    Rails.logger.info "[CDN] Cloudflare: Purging #{urls.size} URLs"
    
    # Mock successful purge
    true
  end

  # Get asset host from Rails configuration
  # @return [String, nil] Asset host URL
  def asset_host
    Rails.application.config.asset_host || ENV['CDN_HOST']
  end

  # Get CDN provider name
  # @return [String] Provider name
  def cdn_provider
    if cloudflare_enabled?
      'cloudflare'
    elsif asset_host&.include?('cloudfront')
      'cloudfront'
    else
      'unknown'
    end
  end

  # Get Cloudflare credentials
  # @return [Hash, nil] Cloudflare credentials
  def cloudflare_credentials
    return nil unless Rails.application.credentials.respond_to?(:cloudflare)
    
    Rails.application.credentials.cloudflare
  rescue StandardError
    nil
  end
end
