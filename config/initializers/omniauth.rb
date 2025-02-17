# config/initializers/omniauth.rb

require 'rspotify/oauth'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :spotify,
  Rails.application.credentials.spotify_key,
  Rails.application.credentials.spotify_secret,
  scope: 'user-read-email user-read-private user-library-read playlist-read-private user-read-recently-played app-remote-control'
end

OmniAuth.config.allowed_request_methods = [:post, :get]