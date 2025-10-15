require 'sidekiq'
require 'securerandom'

class SpotifyTrackPlayerJob
  include Sidekiq::Job

  def perform(*args)
    Rails.logger.debug 'SpotifyTrackPlayerJob'
    @restaurant = Restaurant.find_by(id: args[0])
    return if @restaurant.spotifyuserid.nil?

    me = RSpotify::User.find(@restaurant.spotifyuserid)
    Rails.logger.debug me
    Rails.logger.debug 'step.1'
    player = me.player
    Rails.logger.debug 'step.2'
    nextTrack = Track.find.where(restaurant: @restaurant, sequence: 0).first
    Rails.logger.debug 'step.3'
    player.play_track(nil, "spotify:track:#{nextTrack.externalid}")
    Rails.logger.debug 'step.4'
  end
end
