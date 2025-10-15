require 'sidekiq'
require 'securerandom'

class SpotifyPlaylistSyncJob
  include Sidekiq::Job

  def perform(*args)
    Rails.logger.debug 'SpotifyPlaylistSyncJob'
    @restaurant = Restaurant.find_by(id: args[0])
    Rails.logger.debug @restaurant.name
    Rails.logger.debug @restaurant.spotifyuserid
    return if @restaurant.spotifyuserid.nil?

    me = RSpotify::User.find(@restaurant.spotifyuserid)
    Rails.logger.debug me.to_json
    Track.where(restaurant: @restaurant).destroy_all
    Rails.logger.debug 'delete.tracks'
    playlist = RSpotify::Playlist.find(me.id, '25862YMjra6u07FoPSc7UI')
    Rails.logger.debug playlist.name
    @seq = 1
    playlist.tracks.each do |track|
      Rails.logger.debug track.to_json
      Rails.logger.debug track.name
      @track = Track.new
      @track.restaurant = @restaurant
      @track.externalid = track.uri
      @track.description = track.album.name
      @track.name = track.name
      @track.status = 0
      @pj = track.album.images
      Rails.logger.debug @pj[0]['url']
      @track.image = @pj[0]['url']
      @track.artist = track.artists[0].name
      @track.sequence = @seq
      @track.save
      @seq += 1
    end
  end
end
