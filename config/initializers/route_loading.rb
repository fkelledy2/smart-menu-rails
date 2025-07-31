# config/initializers/route_loading.rb

if Rails.env.development?
  # Only reload routes when they're actually needed
  ActiveSupport::Reloader.to_prepare do
    Rails.application.reload_routes! unless Rails.application.config.cache_classes
  end
  
  # Disable automatic route reloading
  Rails.application.config.after_initialize do
    Rails.application.reloaders.delete_if { |reloader| reloader.is_a?(Rails::Application::RoutesReloader) }
  end
end
