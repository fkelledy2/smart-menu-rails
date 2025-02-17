require 'sidekiq'
require 'securerandom'

class SpotifySyncJob
  include Sidekiq::Job

  def perform(*args)
      puts 'SpotifySyncJob'
      @restaurant = Restaurant.find_by_id(args[0])
      puts @restaurant.name
      puts @restaurant.spotifyuserid
      if @restaurant.spotifyuserid != nil
            me = RSpotify::User.find(@restaurant.spotifyuserid)
            puts me.to_json
            Track.where(restaurant: @restaurant).destroy_all
            puts 'delete.tracks'
            playlist = RSpotify::Playlist.find(me.id, '25862YMjra6u07FoPSc7UI')
            puts playlist.name
            @seq = 1
                    playlist.tracks.each do |track|
                        puts track.to_json
                        puts track.name
                        @track = Track.new
                        @track.restaurant = @restaurant
                        @track.externalid = track.uri
                        @track.description = track.album.name
                        @track.name = track.name
                        @track.status = 0
                        @pj = track.album.images
                        puts @pj[0]['url']
                        @track.image = @pj[0]['url']
                        @track.artist = track.artists[0].name
                        @track.sequence = @seq
                        @track.save
                        @seq = @seq + 1
                    end
      end
  end
end
