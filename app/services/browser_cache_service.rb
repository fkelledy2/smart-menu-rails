# frozen_string_literal: true

# BrowserCacheService
#
# Manages browser caching headers and strategies for optimal client-side caching.
# Provides intelligent cache headers based on content type, user authentication,
# and cacheability requirements.
#
# Usage:
#   BrowserCacheService.set_headers(response, request, current_user)
#   BrowserCacheService.cache_page(response, max_age: 300)
#   BrowserCacheService.no_cache(response)
#
class BrowserCacheService
  include Singleton

  class << self
    delegate :set_headers, :cache_page, :no_cache, :set_etag, :cache_stats, to: :instance
  end

  # Set appropriate cache headers based on content type and request
  # @param response [ActionDispatch::Response] The response object
  # @param request [ActionDispatch::Request] The request object
  # @param current_user [User, nil] The current authenticated user
  def set_headers(response, request, current_user = nil)
    return if response.headers['Cache-Control'].present?

    content_type = response.content_type || 'text/html'
    
    case content_type
    when /html/
      set_html_headers(response, current_user)
    when /json/
      set_json_headers(response, request, current_user)
    when /javascript/
      set_javascript_headers(response)
    when /css/
      set_css_headers(response)
    when /image/
      set_image_headers(response)
    else
      set_default_headers(response)
    end

    add_security_headers(response)
    track_cache_headers(content_type, response.headers['Cache-Control'])
  end

  # Cache a page with specific options
  # @param response [ActionDispatch::Response] The response object
  # @param options [Hash] Caching options
  # @option options [Integer] :max_age Maximum age in seconds
  # @option options [Boolean] :public Public caching (default: false)
  # @option options [Boolean] :must_revalidate Require revalidation (default: true)
  # @option options [Integer] :stale_while_revalidate Stale-while-revalidate time
  def cache_page(response, options = {})
    max_age = options[:max_age] || 300
    public_cache = options[:public] || false
    must_revalidate = options.fetch(:must_revalidate, true)
    stale_while_revalidate = options[:stale_while_revalidate]

    directives = []
    directives << (public_cache ? 'public' : 'private')
    directives << "max-age=#{max_age}"
    directives << 'must-revalidate' if must_revalidate
    directives << "stale-while-revalidate=#{stale_while_revalidate}" if stale_while_revalidate

    response.headers['Cache-Control'] = directives.join(', ')
    response.headers['Vary'] = 'Accept-Encoding, Accept'

    Rails.logger.debug "[Browser Cache] Page cached: #{directives.join(', ')}"
  end

  # Disable caching for sensitive content
  # @param response [ActionDispatch::Response] The response object
  def no_cache(response)
    response.headers['Cache-Control'] = 'private, no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'

    Rails.logger.debug '[Browser Cache] No-cache headers set'
  end

  # Set ETag header for conditional requests
  # @param response [ActionDispatch::Response] The response object
  # @param etag_value [String, Object] ETag value or object to generate ETag from
  # @param weak [Boolean] Use weak ETag (default: false)
  def set_etag(response, etag_value, weak: false)
    etag = if etag_value.is_a?(String)
             etag_value
           elsif etag_value.respond_to?(:cache_key)
             etag_value.cache_key
           else
             Digest::MD5.hexdigest(etag_value.to_s)
           end

    prefix = weak ? 'W/' : ''
    response.headers['ETag'] = "#{prefix}\"#{etag}\""

    Rails.logger.debug "[Browser Cache] ETag set: #{response.headers['ETag']}"
  end

  # Get cache statistics
  # @return [Hash] Cache statistics
  def cache_stats
    stats = Rails.cache.read('browser_cache:stats') || default_stats
    
    {
      total_requests: stats[:total_requests],
      cached_responses: stats[:cached_responses],
      no_cache_responses: stats[:no_cache_responses],
      etag_responses: stats[:etag_responses],
      cache_hit_rate: calculate_hit_rate(stats),
      by_content_type: stats[:by_content_type] || {}
    }
  end

  private

  # Set headers for HTML content
  def set_html_headers(response, current_user)
    if current_user
      # Private caching for authenticated users
      response.headers['Cache-Control'] = 'private, must-revalidate, max-age=0'
    else
      # Short cache for public pages
      response.headers['Cache-Control'] = 'public, max-age=60, must-revalidate'
    end

    response.headers['Vary'] = 'Accept-Encoding, Cookie'
  end

  # Set headers for JSON API responses
  def set_json_headers(response, request, current_user)
    # Check if this is a cacheable API endpoint
    if current_user && cacheable_api_endpoint?(request.path)
      response.headers['Cache-Control'] = 'private, max-age=300, must-revalidate'
      response.headers['Vary'] = 'Accept, Accept-Encoding'
    else
      # Sensitive data or no user - no cache
      no_cache(response)
    end
  end

  # Set headers for JavaScript files
  def set_javascript_headers(response)
    # JavaScript files are typically fingerprinted
    response.headers['Cache-Control'] = 'public, max-age=31536000, immutable'
    response.headers['Vary'] = 'Accept-Encoding'
  end

  # Set headers for CSS files
  def set_css_headers(response)
    # CSS files are typically fingerprinted
    response.headers['Cache-Control'] = 'public, max-age=31536000, immutable'
    response.headers['Vary'] = 'Accept-Encoding'
  end

  # Set headers for image files
  def set_image_headers(response)
    # User-uploaded images - cache for 1 day
    response.headers['Cache-Control'] = 'public, max-age=86400, immutable'
    response.headers['Vary'] = 'Accept-Encoding'
  end

  # Set default headers for unknown content types
  def set_default_headers(response)
    response.headers['Cache-Control'] = 'private, max-age=300, must-revalidate'
    response.headers['Vary'] = 'Accept-Encoding'
  end

  # Add security headers
  def add_security_headers(response)
    response.headers['X-Content-Type-Options'] ||= 'nosniff'
  end

  # Check if API endpoint is cacheable
  def cacheable_api_endpoint?(path)
    # List of cacheable API patterns
    cacheable_patterns = [
      %r{^/api/v1/restaurants/\d+/menus$},
      %r{^/api/v1/restaurants/\d+/menu_items$},
      %r{^/api/v1/restaurants/\d+$}
    ]

    cacheable_patterns.any? { |pattern| path.match?(pattern) }
  end

  # Track cache header usage
  def track_cache_headers(content_type, cache_control)
    return unless Rails.env.production?

    stats = Rails.cache.read('browser_cache:stats') || default_stats
    
    stats[:total_requests] += 1
    stats[:by_content_type][content_type] ||= 0
    stats[:by_content_type][content_type] += 1

    if cache_control&.include?('no-cache')
      stats[:no_cache_responses] += 1
    else
      stats[:cached_responses] += 1
    end

    Rails.cache.write('browser_cache:stats', stats, expires_in: 1.hour)
  rescue StandardError => e
    Rails.logger.error "[Browser Cache] Error tracking stats: #{e.message}"
  end

  # Default statistics structure
  def default_stats
    {
      total_requests: 0,
      cached_responses: 0,
      no_cache_responses: 0,
      etag_responses: 0,
      by_content_type: {}
    }
  end

  # Calculate cache hit rate
  def calculate_hit_rate(stats)
    total = stats[:total_requests]
    return 0.0 if total.zero?

    ((stats[:cached_responses].to_f / total) * 100).round(2)
  end
end
