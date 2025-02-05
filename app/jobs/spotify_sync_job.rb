require 'sidekiq'
require 'securerandom'

class SpotifySyncJob
  include Sidekiq::Job

  def perform(*args)
      puts 'SpotifySyncJob'
      puts args
      @restaurant = Restaurant.find_by_id(args[0])
      if @restaurant.spotifyuserid != nil
            # '31jr3waqr4jdel5x7pwbr6iikzim'
            puts @restaurant.spotifyuserid
            me = RSpotify::User.find(@restaurant.spotifyuserid)
            me.playlists #=> (Playlist array)
            puts
            puts
            me.playlists.each do |playlist|
                playlist.tracks.each do |track|
                    album = RSpotify::Album.find(track.album.id)
                    if album != nil
                        puts
                        puts album.id
                        puts album.name
                        album.tracks.each do |track|
                            puts track.id
                            puts track.name
                        end
                    end
                end
            end
      end
  end
end
