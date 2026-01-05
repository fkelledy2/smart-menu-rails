# config/initializers/omniauth.rb

begin
  require 'rspotify/oauth'
rescue LoadError
end

spotify_key = Rails.application.credentials.spotify_key
spotify_secret = Rails.application.credentials.spotify_secret

if defined?(OmniAuth) && spotify_key.present? && spotify_secret.present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :spotify,
    spotify_key,
    spotify_secret,
    scope: 'user-read-email user-read-private user-library-read playlist-read-private user-read-recently-played app-remote-control'
  end
end

if defined?(OmniAuth)
  OmniAuth.config.allowed_request_methods = [:post, :get]
end