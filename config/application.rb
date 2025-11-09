require_relative "boot"

require "rails/all"
require 'dotenv'
require_relative '../app/middleware/ua_logger'
require_relative '../app/middleware/request_logging_middleware'
require_relative '../app/middleware/metrics_middleware'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SmartMenu
  class Application < Rails::Application
    config.active_job.queue_adapter = :sidekiq
    config.application_name = Rails.application.class.module_parent_name
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    config.middleware.use Rack::Deflater
    # config.middleware.use MetricsMiddleware # Temporarily disabled
    # config.middleware.use RequestLoggingMiddleware # Temporarily disabled

    # Load locale files from config/locales directory
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    config.i18n.default_locale = :en
    config.i18n.available_locales = [:en, :it]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.action_view.field_error_proc = Proc.new { |html_tag, instance| "#{html_tag}".html_safe }

    config.action_view.debug_missing_translation = false

    config.middleware.insert_before 0, UaLogger

    # RSpotify::authenticate(Rails.application.credentials.spotify_key, Rails.application.credentials.spotify_secret)

    Dotenv.load

  end
end
