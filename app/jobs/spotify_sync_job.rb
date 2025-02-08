require 'sidekiq'
require 'securerandom'

class SpotifySyncJob
  include Sidekiq::Job

  def perform(*args)
      puts 'SpotifySyncJob'
      puts args
      @restaurant = Restaurant.find_by_id(args[0])
      if @restaurant.spotifyuserid != nil
            # '31jr3waqr4jdel5x7p:wbr6iikzim'
            me = RSpotify::User.find(@restaurant.spotifyuserid)
            Track.where(restaurant: @restaurant).destroy_all
            me.playlists.each do |playlist|
                playlist.tracks.each do |track|
                    album = RSpotify::Album.find(track.album.id)
                    if album != nil
                        puts album.name
                        album.tracks.each do |track|
                                puts track.name
                                @track = Track.new
                                @track.restaurant = @restaurant
                                @track.externalid = track.id
                                @track.description = album.name
                                @track.name = track.name
                                @track.status = 0
                                @pj = track.album.images
                                puts @pj[0]['url']
                                @track.image = @pj[0]['url']
                                @track.artist = track.artists[0].name
                                @track.save
                        end
                    end
                end
            end
      end
  end
end
