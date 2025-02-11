require 'sidekiq'
require 'securerandom'

class SpotifyPlayJob
  include Sidekiq::Job

  def perform(*args)
      puts 'SpotifyPlayJob'
      @restaurant = Restaurant.find_by_id(args[0])
      if @restaurant.spotifyuserid != nil
            me = RSpotify::User.find(@restaurant.spotifyuserid)
            puts me
            puts 'step.1'
            player = me.player
            puts 'step.2'
            nextTrack = Track.find.where(restaurant: @restaurant, sequence: 0).first
            puts 'step.3'
            player.play_track(nil, "spotify:track:"+nextTrack.externalid)
            puts 'step.4'
      end
  end
end
