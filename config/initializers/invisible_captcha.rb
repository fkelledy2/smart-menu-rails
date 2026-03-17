# frozen_string_literal: true

InvisibleCaptcha.setup do |config|
  # Honeypot field name
  config.honeypots = [:subtitle, :tagline]
  
  # Visual honeypots (hidden with CSS)
  config.visual_honeypots = false
  
  # Timestamp threshold (minimum time to fill form)
  config.timestamp_threshold = 2
  
  # Timestamp enabled
  config.timestamp_enabled = true
  
  # Inject honeypot automatically in forms
  config.injectable_styles = false
  
  # Spinner enabled
  config.spinner_enabled = false
end
