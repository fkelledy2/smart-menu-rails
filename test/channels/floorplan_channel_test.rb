# frozen_string_literal: true

require 'test_helper'

class FloorplanChannelTest < ActionCable::Channel::TestCase
  # FloorplanChannel streams from "floorplan:restaurant:#{restaurant_id}".
  # No authentication is required — any client with a restaurant_id can subscribe.

  def setup
    @restaurant = restaurants(:one)
  end

  test 'subscribes and streams from floorplan channel when restaurant_id is provided' do
    subscribe(restaurant_id: @restaurant.id)

    assert subscription.confirmed?
    assert_has_stream "floorplan:restaurant:#{@restaurant.id}"
  end

  test 'rejects subscription when restaurant_id is blank' do
    subscribe(restaurant_id: nil)
    assert subscription.rejected?
  end

  test 'rejects subscription when restaurant_id param is missing' do
    subscribe({})
    assert subscription.rejected?
  end

  test 'streams only for the subscribed restaurant_id' do
    subscribe(restaurant_id: @restaurant.id)

    assert_has_stream "floorplan:restaurant:#{@restaurant.id}"
    # Verify the stream name is exactly the one for this restaurant, not another.
    assert_not_includes subscription.streams, "floorplan:restaurant:99999"
  end

  test 'unsubscribed does not raise' do
    subscribe(restaurant_id: @restaurant.id)
    assert_nothing_raised { unsubscribe }
  end
end
