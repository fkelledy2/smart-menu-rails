class SessionsController < ApplicationController
  require 'rspotify'

  def spotify_auth
    scopes = %w[
      user-read-email
      user-read-private
      user-library-read
      playlist-read-private
      user-read-recently-played
      app-remote-control
      streaming
    ].join(' ')
    spotify_auth_url = 'https://accounts.spotify.com/authorize?client_id=' + Rails.application.credentials.spotify_key + "&response_type=code&redirect_uri=#{ENV.fetch(
      'SPOTIFY_REDIRECT_URI', nil,
    )}&scope=#{scopes}"
    redirect_to spotify_auth_url, allow_other_host: true
  end

  def spotify_callback
    if params[:code]
      auth_response = RestClient.post('https://accounts.spotify.com/api/token', {
        grant_type: 'authorization_code',
        code: params[:code],
        redirect_uri: ENV.fetch('SPOTIFY_REDIRECT_URI', nil),
        client_id: Rails.application.credentials.spotify_key,
        client_secret: Rails.application.credentials.spotify_secret,
      })
      auth_data = JSON.parse(auth_response.body)
      Rails.logger.debug auth_data
      spotify_user = RSpotify::User.new(auth_data)

      session[:spotify_user] = {
        id: spotify_user.id,
        display_name: spotify_user.display_name,
        email: spotify_user.email,
        token: auth_data['access_token'],
        refresh_token: auth_data['refresh_token'],
        expires_at: Time.now.to_i + auth_data['expires_in'],
      }

      redirect_to '/me'
    else
      render json: { error: 'Authorization failed' }, status: :unauthorized
    end
  end

  def me
    if session[:spotify_user]
      render json: session[:spotify_user]
    else
      render json: { error: 'Not logged in' }, status: :unauthorized
    end
  end

  def logout
    session.delete(:spotify_user)
    render json: { message: 'Logged out' }
  end
end
