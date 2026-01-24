require 'stripe'

Rails.application.config.after_initialize do
  key = begin
    Rails.application.credentials.stripe_secret_key
  rescue StandardError
    nil
  end

  if key.blank?
    key = begin
      Rails.application.credentials.dig(:stripe, :secret_key) ||
        Rails.application.credentials.dig(:stripe, :api_key)
    rescue StandardError
      nil
    end
  end

  key = ENV['STRIPE_SECRET_KEY'] if key.blank?
  Stripe.api_key = key if key.present?
end
