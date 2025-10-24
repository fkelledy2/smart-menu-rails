# frozen_string_literal: true

# CDN Cache Headers Configuration
# Optimizes cache headers for CDN delivery

module CdnCacheControl
  # Cache durations by content type
  CACHE_DURATIONS = {
    'application/javascript' => 1.year,
    'text/javascript' => 1.year,
    'text/css' => 1.year,
    'image/png' => 1.year,
    'image/jpeg' => 1.year,
    'image/jpg' => 1.year,
    'image/gif' => 1.year,
    'image/svg+xml' => 1.year,
    'image/webp' => 1.year,
    'font/woff' => 1.year,
    'font/woff2' => 1.year,
    'font/ttf' => 1.year,
    'font/eot' => 1.year,
    'application/font-woff' => 1.year,
    'application/font-woff2' => 1.year,
    'application/json' => 5.minutes,
    'text/html' => 0, # Don't cache HTML
  }.freeze

  # Generate cache control header for content type
  # @param content_type [String] MIME type
  # @param stale_while_revalidate [Integer, nil] SWR duration in seconds
  # @return [String] Cache-Control header value
  def self.cache_control_for(content_type, stale_while_revalidate: nil)
    duration = CACHE_DURATIONS[content_type] || 1.hour
    
    if duration.zero?
      'no-cache, no-store, must-revalidate'
    else
      parts = ["public", "max-age=#{duration.to_i}"]
      
      # Add stale-while-revalidate for better performance
      swr_duration = stale_while_revalidate || default_swr_duration(content_type)
      parts << "stale-while-revalidate=#{swr_duration}" if swr_duration.positive?
      
      # Add immutable for assets that never change
      parts << "immutable" if immutable_content?(content_type)
      
      parts.join(', ')
    end
  end
  
  # Get default stale-while-revalidate duration for content type
  # @param content_type [String] MIME type
  # @return [Integer] SWR duration in seconds
  def self.default_swr_duration(content_type)
    case content_type
    when /^image\//
      1.day.to_i
    when 'application/javascript', 'text/javascript', 'text/css'
      1.week.to_i
    when 'application/json'
      5.minutes.to_i
    else
      1.hour.to_i
    end
  end
  
  # Check if content type should be marked as immutable
  # @param content_type [String] MIME type
  # @return [Boolean]
  def self.immutable_content?(content_type)
    # Assets with fingerprints are immutable
    %w[
      application/javascript
      text/javascript
      text/css
      image/png
      image/jpeg
      image/jpg
      image/gif
      image/svg+xml
      image/webp
      font/woff
      font/woff2
    ].include?(content_type)
  end

  # Generate CDN-specific cache control header
  # @param content_type [String] MIME type
  # @return [String] CDN-Cache-Control header value
  def self.cdn_cache_control_for(content_type)
    duration = CACHE_DURATIONS[content_type] || 1.hour
    
    if duration.zero?
      'no-cache'
    else
      "public, max-age=#{duration.to_i}"
    end
  end

  # Check if content type should be cached
  # @param content_type [String] MIME type
  # @return [Boolean]
  def self.cacheable?(content_type)
    duration = CACHE_DURATIONS[content_type] || 1.hour
    duration.positive?
  end
end

# Middleware to add CDN cache headers
class CdnCacheHeadersMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)
    
    # Only add headers for successful responses
    if status == 200 && should_add_headers?(env['PATH_INFO'])
      content_type = headers['Content-Type']&.split(';')&.first
      
      if content_type && CdnCacheControl.cacheable?(content_type)
        # Add standard cache control
        headers['Cache-Control'] = CdnCacheControl.cache_control_for(content_type)
        
        # Add CDN-specific headers
        headers['CDN-Cache-Control'] = CdnCacheControl.cdn_cache_control_for(content_type)
        
        # Add Vary header for proper caching
        headers['Vary'] = 'Accept-Encoding'
        
        # Add security headers
        headers['X-Content-Type-Options'] = 'nosniff'
      end
    end
    
    [status, headers, response]
  end

  private

  def should_add_headers?(path)
    # Add headers for asset paths
    path.start_with?('/assets/', '/packs/', '/images/') ||
      path.match?(/\.(js|css|png|jpg|jpeg|gif|svg|woff|woff2|ttf|eot)$/)
  end
end

# Add middleware in production
if Rails.env.production?
  Rails.application.config.middleware.use CdnCacheHeadersMiddleware
end
