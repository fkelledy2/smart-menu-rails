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
    script_src: %w['self' 'unsafe-inline' 'unsafe-eval' https://js.stripe.com https://www.googletagmanager.com https://maps.googleapis.com https://web.squarecdn.com https://sandbox.web.squarecdn.com https://ga.jspm.io https://cdn.jsdelivr.net https://unpkg.com],
    style_src: %w['self' 'unsafe-inline' https://fonts.googleapis.com https://fonts.gstatic.com https://cdnjs.cloudflare.com https://cdn.jsdelivr.net],
    font_src: %w['self' https://fonts.gstatic.com https://cdnjs.cloudflare.com data:],
    img_src: %w['self' data: https: blob:],
    connect_src: %w['self' https://api.stripe.com https://*.sentry.io https://maps.googleapis.com https://maps.gstatic.com https://unpkg.com https://cdn.jsdelivr.net https://ga.jspm.io https://pci.squareup.com https://pci.squareupsandbox.com https://connect.squareup.com https://connect.squareupsandbox.com],
    frame_src: %w['self' https://js.stripe.com https://web.squarecdn.com https://sandbox.web.squarecdn.com],
    object_src: %w['none'],
    base_uri: %w['self']
  }
  
  config.referrer_policy = "strict-origin-when-cross-origin"
end
