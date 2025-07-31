require_relative "boot"

require "rails/all"
require 'dotenv'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SmartMenu
  class Application < Rails::Application
    config.active_job.queue_adapter = :sidekiq
    config.application_name = Rails.application.class.module_parent_name
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Configure autoload paths
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    
    # Ignore non-RB files and specific directories from eager loading
    config.autoload_lib(ignore: %w(assets tasks templates generators middleware))
    
    # Only load the code we need
    config.add_autoload_paths_to_load_path = false
    
    # Disable automatic reloading of classes in development if not needed
    config.enable_dependency_loading = true
    config.autoloader = :classic

    config.middleware.use Rack::Deflater

    config.i18n.load_path += Dir[Rails.root.join("my", "locales", "*.{rb,yml}")]
    config.i18n.default_locale = :en
    config.i18n.available_locales = %w(en it)

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.action_view.field_error_proc = Proc.new { |html_tag, instance| "#{html_tag}".html_safe }

    config.action_view.debug_missing_translation = false

    RSpotify::authenticate(Rails.application.credentials.spotify_key, Rails.application.credentials.spotify_secret)

    Dotenv.load

  end
end
