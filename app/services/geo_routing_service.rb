# frozen_string_literal: true

# Service for geographic routing and location-based optimization
# Routes users to nearest edge locations and optimizes content delivery
class GeoRoutingService
  include Singleton

  class << self
    delegate :detect_location, :optimal_edge_location, :asset_url_for_location,
             :supported_regions, to: :instance
  end

  # Detect user's geographic location from request
  # @param request [ActionDispatch::Request] Request object
  # @return [Hash] Location data with country, region, continent
  def detect_location(request)
    # Try CloudFlare headers first
    country = request.headers['CF-IPCountry'] ||
              request.headers['CloudFront-Viewer-Country'] ||
              detect_from_ip(request.remote_ip)

    continent = country_to_continent(country)
    region = continent_to_region(continent)

    {
      country: country,
      continent: continent,
      region: region,
      ip: request.remote_ip,
    }
  end

  # Get optimal CDN edge location for user's location
  # @param location [Hash] User location data
  # @return [String] Edge location identifier
  def optimal_edge_location(location)
    region = location[:region] || 'us'

    EDGE_LOCATIONS[region] || EDGE_LOCATIONS['us']
  end

  # Get optimized asset URL for user's location
  # @param asset_path [String] Asset path
  # @param request [ActionDispatch::Request] Request object
  # @return [String] Optimized asset URL
  def asset_url_for_location(asset_path, request)
    return asset_path unless cdn_enabled?

    location = detect_location(request)
    edge = optimal_edge_location(location)

    "#{edge}/#{asset_path.sub(%r{^/}, '')}"
  end

  # Get list of supported regions
  # @return [Array<String>] Region codes
  def supported_regions
    EDGE_LOCATIONS.keys
  end

  # Get region statistics
  # @return [Hash] Statistics by region
  def region_stats
    {
      supported_regions: supported_regions,
      edge_locations: EDGE_LOCATIONS,
      cdn_enabled: cdn_enabled?,
    }
  end

  private

  # Edge location URLs by region
  EDGE_LOCATIONS = {
    'us' => ENV['CDN_EDGE_US'] || ENV['CDN_HOST'] || 'https://cdn.mellow.menu',
    'eu' => ENV['CDN_EDGE_EU'] || ENV['CDN_HOST'] || 'https://cdn-eu.mellow.menu',
    'asia' => ENV['CDN_EDGE_ASIA'] || ENV['CDN_HOST'] || 'https://cdn-asia.mellow.menu',
    'oceania' => ENV['CDN_EDGE_OCEANIA'] || ENV['CDN_HOST'] || 'https://cdn-oceania.mellow.menu',
    'sa' => ENV['CDN_EDGE_SA'] || ENV['CDN_HOST'] || 'https://cdn-sa.mellow.menu',
    'africa' => ENV['CDN_EDGE_AFRICA'] || ENV['CDN_HOST'] || 'https://cdn-africa.mellow.menu',
  }.freeze

  # Country to continent mapping
  COUNTRY_TO_CONTINENT = {
    # North America
    'US' => 'NA', 'CA' => 'NA', 'MX' => 'NA',
    # Europe
    'GB' => 'EU', 'DE' => 'EU', 'FR' => 'EU', 'IT' => 'EU', 'ES' => 'EU',
    'NL' => 'EU', 'BE' => 'EU', 'CH' => 'EU', 'AT' => 'EU', 'SE' => 'EU',
    'NO' => 'EU', 'DK' => 'EU', 'FI' => 'EU', 'PL' => 'EU', 'IE' => 'EU',
    # Asia
    'CN' => 'AS', 'JP' => 'AS', 'KR' => 'AS', 'IN' => 'AS', 'SG' => 'AS',
    'TH' => 'AS', 'VN' => 'AS', 'ID' => 'AS', 'MY' => 'AS', 'PH' => 'AS',
    # Oceania
    'AU' => 'OC', 'NZ' => 'OC',
    # South America
    'BR' => 'SA', 'AR' => 'SA', 'CL' => 'SA', 'CO' => 'SA', 'PE' => 'SA',
    # Africa
    'ZA' => 'AF', 'EG' => 'AF', 'NG' => 'AF', 'KE' => 'AF',
  }.freeze

  # Continent to region mapping
  CONTINENT_TO_REGION = {
    'NA' => 'us',
    'EU' => 'eu',
    'AS' => 'asia',
    'OC' => 'oceania',
    'SA' => 'sa',
    'AF' => 'africa',
  }.freeze

  # Detect country from IP address
  # @param ip [String] IP address
  # @return [String] Country code
  def detect_from_ip(ip)
    # Default to US if we can't detect
    # In production, this would use MaxMind GeoIP or similar
    return 'US' if ip.nil? || ip == '127.0.0.1' || ip.start_with?('192.168.', '10.', '172.')

    # Mock detection for development
    'US'
  end

  # Convert country code to continent
  # @param country [String] Country code
  # @return [String] Continent code
  def country_to_continent(country)
    COUNTRY_TO_CONTINENT[country] || 'NA'
  end

  # Convert continent to region
  # @param continent [String] Continent code
  # @return [String] Region identifier
  def continent_to_region(continent)
    CONTINENT_TO_REGION[continent] || 'us'
  end

  # Check if CDN is enabled
  # @return [Boolean]
  def cdn_enabled?
    ENV['CDN_HOST'].present? || Rails.application.config.asset_host.present?
  end
end
