require 'stripe'

Rails.application.config.after_initialize do
  env_key = ENV['STRIPE_SECRET_KEY'].presence

  credentials_key = begin
    Rails.application.credentials.stripe_secret_key
  rescue StandardError
    nil
  end

  if credentials_key.blank?
    credentials_key = begin
      Rails.application.credentials.dig(:stripe, :secret_key) ||
        Rails.application.credentials.dig(:stripe, :api_key)
    rescue StandardError
      nil
    end
  end

  key = if Rails.env.production?
    env_key || credentials_key
  else
    credentials_key.presence || env_key
  end

  key_source = if key.blank?
    'none'
  elsif key == env_key
    'env'
  else
    'credentials'
  end

  Rails.logger.warn("[Stripe] initializer api_key_source=#{key_source}")
  Stripe.api_key = key if key.present?
end
