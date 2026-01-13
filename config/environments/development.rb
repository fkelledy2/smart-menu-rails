require "active_support/core_ext/integer/time"

Rails.application.configure do

  # Bullet gem configuration for N+1 query detection - reduced verbosity
  config.after_initialize do
    if defined?(Bullet)
      Bullet.enable        = true
      Bullet.alert         = false  # Disable JavaScript alerts
      Bullet.bullet_logger = true  # Log to bullet.log file
      Bullet.console       = false # Disable console logging to reduce noise
      Bullet.rails_logger  = false # Disable Rails logger to reduce noise
      Bullet.add_footer    = false # Disable HTML footer to reduce noise

      # Additional Bullet configurations for better detection
      Bullet.counter_cache_enable = false
      Bullet.unused_eager_loading_enable = true
      Bullet.stacktrace_includes = [ 'app' ]
      Bullet.stacktrace_excludes = [ 'vendor', 'lib', 'gems' ]

      # Skip certain paths that might have intentional N+1 queries
      Bullet.skip_html_injection = false

      # Bullet will automatically log to log/bullet.log when bullet_logger = true
      
      # Note: Bullet logs to Rails.logger by default when bullet_logger = true
    end
  end

  # config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
      address:              'smtp.gmail.com',
      port:                 587,
      domain:               'gmail.com',
      user_name:            Rails.application.credentials.gmail_user_name,
      password:             Rails.application.credentials.gmail_app_password,
      authentication:       'plain',
      enable_starttls_auto: true
  }

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  # Reduce log verbosity - only show warnings and above
  config.log_level = :warn
  
  # Use the standard formatter
  config.log_formatter = ::Logger::Formatter.new
  config.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
  
  # Remove request_id from logs to reduce noise
  config.log_tags = []
  config.enable_reloading = true
  
  # Log to STDOUT for better visibility in development
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    config.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
  end

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = ENV['USE_S3_STORAGE'].to_s.downcase == 'true' ? :amazon : :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Disable verbose query logging
  config.active_record.verbose_query_logs = false

  # Disable verbose job logging
  config.active_job.verbose_enqueue_logs = false

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  config.identity_cache_enabled = true

  #   config.after_initialize do
  #     ActiveRecord::Base.logger = Rails.logger.clone
  #     ActiveRecord::Base.logger.level = Logger::DEBUG
  #   end

end
