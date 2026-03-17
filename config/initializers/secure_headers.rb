# frozen_string_literal: true

SecureHeaders::Configuration.default do |config|
  # HSTS - Force HTTPS for 1 year including subdomains
  config.hsts = "max-age=#{1.year.to_i}; includeSubDomains"
  
  # X-Frame-Options - Prevent clickjacking
  config.x_frame_options = "DENY"
  
  # X-Content-Type-Options - Prevent MIME sniffing
  config.x_content_type_options = "nosniff"
  
  # X-XSS-Protection - Enable XSS filtering
  config.x_xss_protection = "1; mode=block"
  
  # Content Security Policy
  config.csp = {
    default_src: %w['self'],
    script_src: %w['self' 'unsafe-inline' 'unsafe-eval' https://js.stripe.com https://www.googletagmanager.com],
    style_src: %w['self' 'unsafe-inline' https://fonts.googleapis.com],
    font_src: %w['self' https://fonts.gstatic.com data:],
    img_src: %w['self' data: https: blob:],
    connect_src: %w['self' https://api.stripe.com https://*.sentry.io],
    frame_src: %w['self' https://js.stripe.com],
    object_src: %w['none'],
    base_uri: %w['self']
  }
  
  # Referrer Po  # Referrer Po  # Referrer y = "strict-origin-when-cross-origin"
end
