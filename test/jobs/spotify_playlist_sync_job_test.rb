# frozen_string_literal: true

require 'test_helper'

class SpotifyPlaylistSyncJobTest < ActiveSupport::TestCase
  # SpotifyPlaylistSyncJob syncs Spotify tracks for a restaurant.
  # Tests cover: early-return guards and the happy-path with RSpotify stubbed.

  def setup
    @restaurant = restaurants(:one)
  end

  test 'perform is a no-op when restaurant id does not exist' do
    assert_nothing_raised { SpotifyPlaylistSyncJob.new.perform(-999) }
  end

  test 'perform is a no-op when restaurant has no spotifyuserid' do
    @restaurant.update!(spotifyuserid: nil)

    # Should return early without touching RSpotify
    rspotify_called = false
    RSpotify::User.stub(:find, lambda { |_id|
      rspotify_called = true
      nil
    },) do
      SpotifyPlaylistSyncJob.new.perform(@restaurant.id)
    end

    assert_not rspotify_called, 'RSpotify::User.find should not be called without a spotifyuserid'
  end

  test 'perform syncs tracks from Spotify playlist' do
    @restaurant.update!(spotifyuserid: 'spotify_user_123')

    fake_artist  = Struct.new(:name).new('Test Artist')
    fake_image   = { 'url' => 'https://example.com/image.jpg' }
    fake_album   = Struct.new(:name, :images).new('Test Album', [fake_image])
    fake_track   = Struct.new(:uri, :name, :album, :artists).new(
      'spotify:track:abc123',
      'Test Track',
      fake_album,
      [fake_artist],
    )
    fake_playlist = Struct.new(:name, :tracks).new('Test Playlist', [fake_track])
    fake_user     = Struct.new(:id, :to_json).new('spotify_user_123', '{}')

    RSpotify::User.stub(:find, ->(_id) { fake_user }) do
      RSpotify::Playlist.stub(:find, ->(_uid, _pid) { fake_playlist }) do
        Track.where(restaurant: @restaurant).destroy_all

        assert_difference 'Track.where(restaurant: @restaurant).count', 1 do
          SpotifyPlaylistSyncJob.new.perform(@restaurant.id)
        end
      end
    end

    track = Track.where(restaurant: @restaurant).last
    assert_equal 'Test Track', track.name
    assert_equal 'spotify:track:abc123', track.externalid
    assert_equal 'Test Artist', track.artist
  end

  test 'perform deletes existing tracks before syncing' do
    @restaurant.update!(spotifyuserid: 'spotify_user_123')

    # Pre-existing track
    Track.create!(
      restaurant: @restaurant,
      name: 'Old Track',
      externalid: 'old:uri',
      status: 0,
      sequence: 1,
    )

    fake_artist  = Struct.new(:name).new('New Artist')
    fake_image   = { 'url' => 'https://example.com/img.jpg' }
    fake_album   = Struct.new(:name, :images).new('New Album', [fake_image])
    fake_track   = Struct.new(:uri, :name, :album, :artists).new('spotify:track:new', 'New Track', fake_album, [fake_artist])
    fake_playlist = Struct.new(:name, :tracks).new('Playlist', [fake_track])
    fake_user = Struct.new(:id, :to_json).new('spotify_user_123', '{}')

    RSpotify::User.stub(:find, ->(_id) { fake_user }) do
      RSpotify::Playlist.stub(:find, ->(_uid, _pid) { fake_playlist }) do
        SpotifyPlaylistSyncJob.new.perform(@restaurant.id)
      end
    end

    track_names = Track.where(restaurant: @restaurant).pluck(:name)
    assert_includes track_names, 'New Track'
    assert_not_includes track_names, 'Old Track'
  end
end
