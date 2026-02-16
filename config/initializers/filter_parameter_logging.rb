# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  :api_key, :credit_card, :card_number, :cvv, :cvc,
  :authorization, :stripe_signature, :webhook_secret,
  :wifiPassword, :p256dh_key, :auth_key, :access_token, :access_token_secret,
]
