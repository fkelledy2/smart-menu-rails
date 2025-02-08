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
            # '31jr3waqr4jdel5x7p:wbr6iikzim'
            me = RSpotify::User.find(@restaurant.spotifyuserid)
            puts me
            Track.where(restaurant: @restaurant).destroy_all
            puts 'delete.tracks'
            me.playlists.each do |playlist|
                puts playlist.name
#                 if playlist.id == '25862YMjra6u07FoPSc7UI'
                    playlist.tracks.each do |track|
                        puts track
                                    puts track.name
                                    @track = Track.new
                                    @track.restaurant = @restaurant
                                    @track.externalid = track.id
                                    @track.description = track.album.name
                                    @track.name = track.name
                                    @track.status = 0
                                    @pj = track.album.images
                                    puts @pj[0]['url']
                                    @track.image = @pj[0]['url']
                                    @track.artist = track.artists[0].name
                                    @track.save
#                         album = RSpotify::Album.find(track.album.id)
#                         if album != nil
#                             puts album.name
#                             album.tracks.each do |track|
#                             end
#                         end
                    end
#                 end
            end
      end
  end
end
