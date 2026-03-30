# frozen_string_literal: true

require 'rspotify'

module Restaurants
  class SpotifyController < BaseController
    skip_after_action :verify_authorized, only: %i[spotify_auth spotify_callback logout]

    def spotify_auth
      session[:spotify_restaurant_id] = params[:restaurant_id] if params[:restaurant_id]
      session[:spotify_return_to] = params[:return_to] if params[:return_to]

      scopes = %w[
        user-read-email
        user-read-private
        user-library-read
        playlist-read-private
        user-read-recently-played
        app-remote-control
        streaming
      ].join(' ')

      spotify_auth_url = 'https://accounts.spotify.com/authorize?client_id=' \
        + Rails.application.credentials.spotify_key \
        + "&response_type=code&redirect_uri=#{ENV.fetch('SPOTIFY_REDIRECT_URI', nil)}&scope=#{scopes}"

      redirect_to spotify_auth_url, allow_other_host: true
    end

    def spotify_callback
      unless params[:code]
        render json: { error: 'Authorization failed' }, status: :unauthorized
        return
      end

      credentials = Base64.strict_encode64(
        "#{Rails.application.credentials.spotify_key}:#{Rails.application.credentials.spotify_secret}",
      )

      form_data = URI.encode_www_form({
        grant_type: 'authorization_code',
        code: params[:code],
        redirect_uri: ENV.fetch('SPOTIFY_REDIRECT_URI', nil),
      })

      auth_response = RestClient.post(
        'https://accounts.spotify.com/api/token',
        form_data,
        {
          Authorization: "Basic #{credentials}",
          content_type: 'application/x-www-form-urlencoded',
          accept: 'application/json',
        },
      )

      auth_data = JSON.parse(auth_response.body)
      Rails.logger.debug { "Spotify auth response: #{auth_data}" }

      user_response = RestClient.get(
        'https://api.spotify.com/v1/me',
        { Authorization: "Bearer #{auth_data['access_token']}" },
      )
      user_data = JSON.parse(user_response.body)

      session[:spotify_user] = {
        id: user_data['id'],
        display_name: user_data['display_name'],
        email: user_data['email'],
        token: auth_data['access_token'],
        refresh_token: auth_data['refresh_token'],
        expires_at: Time.now.to_i + auth_data['expires_in'],
      }

      if session[:spotify_restaurant_id]
        @restaurant = Restaurant.find_by(id: session[:spotify_restaurant_id])
        unless @restaurant
          Rails.logger.warn "[SpotifyController] Restaurant not found for id=#{session[:spotify_restaurant_id]}"
          redirect_to root_url, alert: 'Restaurant not found.'
          return
        end

        @restaurant.spotifyaccesstoken = auth_data['access_token']
        @restaurant.spotifyrefreshtoken = auth_data['refresh_token']
        @restaurant.spotifyuserid = user_data['id']
        @restaurant.save

        Rails.logger.info "Spotify connected for restaurant: #{@restaurant.name} (ID: #{@restaurant.id})"
        # Validate the stored return_to path to prevent open redirect via the session value.
        stored_path = session.delete(:spotify_return_to)
        return_path = if stored_path.present? && stored_path.start_with?('/')
                        stored_path
                      else
                        edit_restaurant_path(@restaurant, section: 'jukebox')
                      end
        redirect_to return_path
      else
        redirect_to root_url
      end
    end

    def logout
      session.delete(:spotify_user)
      render json: { message: 'Logged out' }
    end
  end
end
