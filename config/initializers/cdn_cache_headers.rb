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
  # @return [String] Cache-Control header value
  def self.cache_control_for(content_type)
    duration = CACHE_DURATIONS[content_type] || 1.hour
    
    if duration.zero?
      'no-cache, no-store, must-revalidate'
    else
      "public, max-age=#{duration.to_i}, immutable"
    end
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
