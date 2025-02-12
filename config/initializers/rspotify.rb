require 'rspotify'

RSpotify::authenticate(Rails.application.credentials.spotify_key, Rails.application.credentials.spotify_secret)
