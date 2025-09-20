# config/initializers/openai.rb

begin
  require 'openai'
rescue LoadError
  # Gem not installed yet (e.g., during assets:precompile on CI) — skip configuring
end

if defined?(OpenAI)
  api_key = Rails.application.credentials.openai_api_key || ENV['OPENAI_API_KEY']
  if api_key.present?
    timeout_seconds = (ENV['OPENAI_TIMEOUT'] || 120).to_i
    Rails.configuration.x.openai_client = OpenAI::Client.new(
      access_token: api_key,
      request_timeout: timeout_seconds
    )
  else
    Rails.logger.info 'OpenAI initializer: no API key configured; client not initialized'
  end
end
