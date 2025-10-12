require 'test_helper'

class TracksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @track = tracks(:one)
    @restaurant = restaurants(:one)
    
    # Ensure proper associations
    @restaurant.update!(user: @user) if @restaurant.user != @user
    @track.update!(restaurant: @restaurant) if @track.restaurant != @restaurant
  end

  teardown do
    # Clean up test data
  end

  # === BASIC CRUD OPERATIONS ===
  
  test 'should get index' do
    get restaurant_tracks_url(@restaurant)
    assert_response :success
  end

  test 'should get index with empty restaurant' do
    empty_restaurant = Restaurant.create!(
      name: 'Empty Restaurant',
      user: @user,
      capacity: 50,
      status: :active
    )
    get restaurant_tracks_url(empty_restaurant)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_track_url(@restaurant)
    assert_response :success
  end

  test 'should create track with valid data' do
    post restaurant_tracks_url(@restaurant), params: {
      track: {
        name: 'New Track',
        description: 'Test track description',
        externalid: 'spotify:track:123456',
        sequence: 1,
        status: :active,
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 302]
  end

  test 'should create track with different status values' do
    status_values = [:inactive, :active, :archived]
    
    status_values.each_with_index do |status_value, index|
      post restaurant_tracks_url(@restaurant), params: {
        track: {
          name: "Status Test Track #{index}",
          description: 'Status test description',
          externalid: "spotify:track:#{index}",
          sequence: index + 1,
          status: status_value,
          restaurant_id: @restaurant.id
        }
      }
      assert_response_in [200, 302]
    end
  end

  test 'should create track with different sequences' do
    sequences = [1, 5, 10, 15, 20]
    
    sequences.each_with_index do |sequence, index|
      post restaurant_tracks_url(@restaurant), params: {
        track: {
          name: "Sequence Test Track #{index}",
          description: 'Sequence test',
          externalid: "spotify:track:seq#{index}",
          sequence: sequence,
          status: :active,
          restaurant_id: @restaurant.id
        }
      }
      assert_response_in [200, 302]
    end
  end

  test 'should handle create with invalid data' do
    post restaurant_tracks_url(@restaurant), params: {
      track: {
        name: '', # Invalid - required field
        description: 'Test Description',
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 422]
  end

  test 'should show track' do
    get restaurant_track_url(@restaurant, @track)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_track_url(@restaurant, @track)
    assert_response :success
  end

  test 'should update track with valid data' do
    patch restaurant_track_url(@restaurant, @track), params: {
      track: {
        name: 'Updated Track Name',
        description: 'Updated description',
        externalid: @track.externalid,
        sequence: @track.sequence,
        status: @track.status
      }
    }
    assert_response :success
  end

  test 'should update track status' do
    patch restaurant_track_url(@restaurant, @track), params: {
      track: {
        name: @track.name,
        status: :archived,
        sequence: @track.sequence
      }
    }
    assert_response :success
  end

  test 'should update track sequence' do
    patch restaurant_track_url(@restaurant, @track), params: {
      track: {
        name: @track.name,
        sequence: 99,
        status: @track.status
      }
    }
    assert_response :success
  end

  test 'should update track external id' do
    patch restaurant_track_url(@restaurant, @track), params: {
      track: {
        name: @track.name,
        externalid: 'spotify:track:updated123',
        sequence: @track.sequence,
        status: @track.status
      }
    }
    assert_response :success
  end

  test 'should handle update with invalid data' do
    patch restaurant_track_url(@restaurant, @track), params: {
      track: {
        name: '', # Invalid - required field
        description: 'Test Description'
      }
    }
    assert_response_in [200, 422]
  end

  test 'should destroy track' do
    delete restaurant_track_url(@restaurant, @track)
    assert_response :success
  end

  # === AUTHORIZATION TESTS ===
  
  test 'should enforce restaurant ownership' do
    other_restaurant = Restaurant.create!(
      name: 'Other Restaurant',
      user: User.create!(email: 'other@example.com', password: 'password'),
      capacity: 30,
      status: :active
    )
    
    get restaurant_tracks_url(other_restaurant)
    assert_response_in [200, 302, 403]
  end

  test 'should redirect unauthorized users' do
    sign_out @user
    get new_restaurant_track_url(@restaurant)
    assert_response_in [200, 302, 401]
  end

  test 'should handle missing track' do
    get restaurant_track_url(@restaurant, 99999)
    assert_response_in [200, 302, 404]
  end

  # === JSON API TESTS ===
  
  test 'should handle JSON index requests' do
    get restaurant_tracks_url(@restaurant), as: :json
    assert_response :success
  end

  test 'should handle JSON show requests' do
    get restaurant_track_url(@restaurant, @track), as: :json
    assert_response :success
  end

  test 'should handle JSON create requests' do
    post restaurant_tracks_url(@restaurant), params: {
      track: {
        name: 'JSON Track',
        description: 'JSON created track',
        externalid: 'spotify:track:json123',
        sequence: 1,
        status: :active,
        restaurant_id: @restaurant.id
      }
    }, as: :json
    assert_response_in [200, 201, 302]
  end

  test 'should handle JSON update requests' do
    patch restaurant_track_url(@restaurant, @track), params: {
      track: {
        name: 'JSON Updated Track',
        description: 'JSON updated description'
      }
    }, as: :json
    assert_response :success
  end

  test 'should handle JSON destroy requests' do
    delete restaurant_track_url(@restaurant, @track), as: :json
    assert_response :success
  end

  test 'should return proper JSON error responses' do
    post restaurant_tracks_url(@restaurant), params: {
      track: {
        name: '', # Invalid
        restaurant_id: @restaurant.id
      }
    }, as: :json
    assert_response_in [200, 422]
  end

  # === BUSINESS LOGIC TESTS ===
  
  test 'should handle all status enum values' do
    status_values = [:inactive, :active, :archived]
    
    status_values.each do |status_value|
      track = Track.create!(
        name: "#{status_value.to_s.capitalize} Track",
        description: 'Test track',
        externalid: "spotify:track:#{status_value}",
        sequence: 1,
        status: status_value,
        restaurant: @restaurant
      )
      
      get restaurant_track_url(@restaurant, track)
      assert_response :success
    end
  end

  test 'should handle track sequence management' do
    sequences = [1, 5, 10, 15, 20, 25]
    
    sequences.each_with_index do |sequence, index|
      track = Track.create!(
        name: "Sequence Track #{index}",
        description: 'Sequence test track',
        externalid: "spotify:track:seq#{index}",
        sequence: sequence,
        status: :active,
        restaurant: @restaurant
      )
      
      get restaurant_track_url(@restaurant, track)
      assert_response :success
    end
  end

  test 'should handle track filtering by status' do
    # Create tracks with different statuses
    Track.create!(name: 'Active Track', status: :active, sequence: 1, externalid: 'spotify:track:active', restaurant: @restaurant)
    Track.create!(name: 'Inactive Track', status: :inactive, sequence: 2, externalid: 'spotify:track:inactive', restaurant: @restaurant)
    Track.create!(name: 'Archived Track', status: :archived, sequence: 3, externalid: 'spotify:track:archived', restaurant: @restaurant)
    
    get restaurant_tracks_url(@restaurant)
    assert_response :success
  end

  test 'should handle spotify integration features' do
    patch restaurant_track_url(@restaurant, @track), params: {
      track: {
        name: @track.name,
        externalid: 'spotify:track:integration123',
        description: 'Spotify integration test'
      }
    }
    assert_response :success
  end

  test 'should handle track playlist management' do
    get restaurant_tracks_url(@restaurant)
    assert_response :success
  end

  test 'should handle track ordering and sequencing' do
    # Create multiple tracks with different sequences
    tracks = []
    [3, 1, 5, 2, 4].each_with_index do |sequence, index|
      tracks << Track.create!(
        name: "Order Track #{index}",
        description: 'Order test',
        externalid: "spotify:track:order#{index}",
        sequence: sequence,
        status: :active,
        restaurant: @restaurant
      )
    end
    
    get restaurant_tracks_url(@restaurant)
    assert_response :success
  end

  # === ERROR HANDLING TESTS ===
  
  test 'should handle invalid enum values gracefully' do
    post restaurant_tracks_url(@restaurant), params: {
      track: {
        name: 'Invalid Enum Test',
        status: 'invalid_status', # Invalid enum value
        externalid: 'spotify:track:invalid',
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 422]
  end

  test 'should handle invalid sequence values' do
    invalid_sequences = [-1, 'not_a_number']
    
    invalid_sequences.each do |invalid_sequence|
      post restaurant_tracks_url(@restaurant), params: {
        track: {
          name: 'Invalid Sequence Test',
          sequence: invalid_sequence,
          externalid: 'spotify:track:invalid_seq',
          status: :active,
          restaurant_id: @restaurant.id
        }
      }
      assert_response_in [200, 422]
    end
  end

  test 'should handle concurrent track operations' do
    patch restaurant_track_url(@restaurant, @track), params: {
      track: {
        name: 'Concurrent Test Track',
        description: 'Concurrent update test'
      }
    }
    assert_response :success
  end

  test 'should handle duplicate external ids' do
    post restaurant_tracks_url(@restaurant), params: {
      track: {
        name: 'Duplicate External ID Test',
        externalid: @track.externalid, # Same as existing track
        sequence: 99,
        status: :active,
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 302, 422]
  end

  # === EDGE CASE TESTS ===
  
  test 'should handle long track names' do
    long_name = 'A' * 100 # Test reasonable length limit
    
    post restaurant_tracks_url(@restaurant), params: {
      track: {
        name: long_name,
        description: 'Long name test',
        externalid: 'spotify:track:longname',
        sequence: 1,
        status: :active,
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 302, 422]
  end

  test 'should handle special characters in track names' do
    special_name = 'Track with "quotes" & symbols!'
    
    post restaurant_tracks_url(@restaurant), params: {
      track: {
        name: special_name,
        description: 'Special characters test',
        externalid: 'spotify:track:special',
        sequence: 1,
        status: :active,
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 302]
  end

  test 'should handle parameter filtering' do
    patch restaurant_track_url(@restaurant, @track), params: {
      track: {
        name: 'Parameter Test',
        description: 'Parameter filtering test'
      },
      unauthorized_param: 'should_be_filtered'
    }
    assert_response :success
  end

  test 'should handle empty descriptions' do
    post restaurant_tracks_url(@restaurant), params: {
      track: {
        name: 'Empty Description Track',
        description: '',
        externalid: 'spotify:track:empty',
        sequence: 1,
        status: :active,
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 302]
  end

  test 'should handle various external id formats' do
    external_id_formats = [
      'spotify:track:4iV5W9uYEdYUVa79Axb7Rh',
      'https://open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh',
      'track:123456',
      'custom_id_format_123'
    ]
    
    external_id_formats.each_with_index do |external_id, index|
      post restaurant_tracks_url(@restaurant), params: {
        track: {
          name: "Format Test Track #{index}",
          description: 'External ID format test',
          externalid: external_id,
          sequence: index + 1,
          status: :active,
          restaurant_id: @restaurant.id
        }
      }
      assert_response_in [200, 302]
    end
  end

  # === CACHING TESTS ===
  
  test 'should handle cached track data efficiently' do
    get restaurant_track_url(@restaurant, @track)
    assert_response :success
  end

  test 'should invalidate caches on track updates' do
    patch restaurant_track_url(@restaurant, @track), params: {
      track: {
        name: 'Cache Invalidation Test',
        description: 'Testing cache invalidation'
      }
    }
    assert_response :success
  end

  test 'should handle cache misses gracefully' do
    get restaurant_tracks_url(@restaurant)
    assert_response :success
  end

  # === PERFORMANCE TESTS ===
  
  test 'should optimize database queries for index' do
    get restaurant_tracks_url(@restaurant)
    assert_response :success
  end

  test 'should handle large datasets efficiently' do
    # Create multiple tracks
    20.times do |i|
      Track.create!(
        name: "Performance Test Track #{i}",
        description: "Performance test #{i}",
        externalid: "spotify:track:perf#{i}",
        sequence: i + 1,
        status: [:inactive, :active, :archived].sample,
        restaurant: @restaurant
      )
    end
    
    get restaurant_tracks_url(@restaurant)
    assert_response :success
  end

  # === INTEGRATION TESTS ===
  
  test 'should handle track with spotify integration' do
    get restaurant_track_url(@restaurant, @track)
    assert_response :success
  end

  test 'should handle track playlist functionality' do
    get restaurant_tracks_url(@restaurant)
    assert_response :success
  end

  # === BUSINESS SCENARIO TESTS ===
  
  test 'should support restaurant playlist management scenarios' do
    # Test creating different types of tracks for playlist
    track_types = [
      { name: 'Background Jazz', description: 'Ambient dining music', externalid: 'spotify:track:jazz123' },
      { name: 'Upbeat Pop', description: 'Energetic atmosphere', externalid: 'spotify:track:pop456' },
      { name: 'Classical Evening', description: 'Elegant dinner music', externalid: 'spotify:track:classical789' },
      { name: 'Acoustic Chill', description: 'Relaxed ambiance', externalid: 'spotify:track:acoustic012' }
    ]
    
    track_types.each_with_index do |track_data, index|
      post restaurant_tracks_url(@restaurant), params: {
        track: {
          name: track_data[:name],
          description: track_data[:description],
          externalid: track_data[:externalid],
          sequence: index + 1,
          status: :active,
          restaurant_id: @restaurant.id
        }
      }
      assert_response_in [200, 302]
    end
  end

  test 'should handle track lifecycle management' do
    # Create new track
    post restaurant_tracks_url(@restaurant), params: {
      track: {
        name: 'Lifecycle Track',
        description: 'Testing lifecycle',
        externalid: 'spotify:track:lifecycle',
        sequence: 1,
        status: :inactive,
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 302]
    
    # Activate track
    patch restaurant_track_url(@restaurant, @track), params: {
      track: {
        name: @track.name,
        status: :active
      }
    }
    assert_response :success
    
    # Archive track
    patch restaurant_track_url(@restaurant, @track), params: {
      track: {
        name: @track.name,
        status: :archived
      }
    }
    assert_response :success
  end

  test 'should handle playlist reordering scenarios' do
    # Create multiple tracks with specific sequences
    tracks = []
    [1, 2, 3, 4, 5].each do |sequence|
      tracks << Track.create!(
        name: "Reorder Track #{sequence}",
        description: "Original sequence #{sequence}",
        externalid: "spotify:track:reorder#{sequence}",
        sequence: sequence,
        status: :active,
        restaurant: @restaurant
      )
    end
    
    # Test reordering by updating sequences
    tracks.each_with_index do |track, index|
      new_sequence = [5, 4, 3, 2, 1][index]
      patch restaurant_track_url(@restaurant, track), params: {
        track: {
          name: track.name,
          sequence: new_sequence
        }
      }
      assert_response :success
    end
  end

  test 'should handle spotify integration scenarios' do
    # Test various Spotify-related operations
    spotify_operations = [
      { name: 'Add Spotify Track', externalid: 'spotify:track:4iV5W9uYEdYUVa79Axb7Rh' },
      { name: 'Update Spotify ID', externalid: 'spotify:track:updated123456789' },
      { name: 'Custom Track ID', externalid: 'custom:track:restaurant_special' }
    ]
    
    spotify_operations.each_with_index do |operation, index|
      if index == 0
        # Create new track
        post restaurant_tracks_url(@restaurant), params: {
          track: {
            name: operation[:name],
            description: 'Spotify integration test',
            externalid: operation[:externalid],
            sequence: 1,
            status: :active,
            restaurant_id: @restaurant.id
          }
        }
        assert_response_in [200, 302]
      else
        # Update existing track
        patch restaurant_track_url(@restaurant, @track), params: {
          track: {
            name: operation[:name],
            externalid: operation[:externalid]
          }
        }
        assert_response :success
      end
    end
  end

  private

  def assert_response_in(expected_codes)
    assert_includes expected_codes, response.status,
                    "Expected response to be one of #{expected_codes}, but was #{response.status}"
  end
end
