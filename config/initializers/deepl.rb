deepl_enabled_env = ENV['SMART_MENU_DEEPL_ENABLED']
deepl_feature_enabled = if deepl_enabled_env.nil? || deepl_enabled_env.to_s.strip == ''
                          true
                        else
                          deepl_enabled_env.to_s.downcase == 'true'
                        end

begin
  require 'deepl' if deepl_feature_enabled
rescue LoadError
  deepl_feature_enabled = false
end

if deepl_feature_enabled && defined?(DeepL)
  api_key = Rails.application.credentials.dig(:deepl, :api_key) || Rails.application.credentials.deepl_api_key || ENV['DEEPL_API_KEY']
  if api_key.present?
    DeepL.configure do |config|
      config.auth_key = api_key
      config.host = 'https://api-free.deepl.com' # Default value is 'https://api.deepl.com'
      config.version = 'v1' # Default value is 'v2'
    end
  else
    Rails.logger.info 'DeepL initializer: no API key configured; client not initialized'
  end
end
