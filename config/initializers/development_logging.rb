# Development logging configuration
# Set VERBOSE_LOGS=true to enable detailed logging in development

if Rails.env.development? && ENV['VERBOSE_LOGS'] == 'true'
  Rails.application.configure do
    # Enable verbose logging
    config.log_level = :debug
    
    # Re-enable log tags
    config.log_tags = [
      :request_id,
      -> request { "IP:#{request.remote_ip}" },
      -> request { "User:#{request.env['warden']&.user&.id || 'anonymous'}" }
    ]
    
    # Re-enable ActiveRecord logging
    ActiveRecord::Base.logger = Rails.logger
    
    # Re-enable APM
    config.enable_apm = true
    
    Rails.logger.info "[DEV] Verbose logging enabled via VERBOSE_LOGS=true"
  end
  
  # Re-enable Bullet console/rails logging
  Rails.application.config.after_initialize do
    if defined?(Bullet)
      Bullet.console = true
      Bullet.rails_logger = true
      Bullet.add_footer = true
      Rails.logger.info "[DEV] Bullet verbose logging enabled"
    end
  end
end
