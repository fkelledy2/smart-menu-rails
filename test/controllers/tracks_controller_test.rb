require 'test_helper'

class TracksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @track = tracks(:one)
    @restaurant = restaurants(:one)
  end

  test 'should get index' do
    get restaurant_tracks_url(@restaurant)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_track_url(@restaurant)
    assert_response :success
  end

  #   test "should create track" do
  #     assert_difference("Track.count") do
  #       post tracks_url, params: { track: { description: @track.description, externalid: @track.externalid, image: @track.image, name: @track.name, restaurant_id: @track.restaurant_id, sequence: @track.sequence } }
  #     end
  #     assert_redirected_to track_url(Track.last)
  #   end

  test 'should show track' do
    get restaurant_track_url(@restaurant, @track)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_track_url(@restaurant, @track)
    assert_response :success
  end
end
