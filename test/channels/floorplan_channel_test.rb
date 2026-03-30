# frozen_string_literal: true

require 'test_helper'

class FloorplanChannelTest < ActionCable::Channel::TestCase
  # FloorplanChannel streams from "floorplan:restaurant:#{restaurant_id}".
  # Authentication is required — only restaurant owners and employees may subscribe.

  def setup
    @user       = users(:one)
    @restaurant = restaurants(:one)
  end

  test 'subscribes and streams from floorplan channel when authenticated owner provides restaurant_id' do
    stub_connection current_user: @user

    subscribe(restaurant_id: @restaurant.id)

    assert subscription.confirmed?
    assert_has_stream "floorplan:restaurant:#{@restaurant.id}"
  end

  test 'rejects subscription when restaurant_id is blank' do
    stub_connection current_user: @user

    subscribe(restaurant_id: nil)
    assert subscription.rejected?
  end

  test 'rejects subscription when restaurant_id param is missing' do
    stub_connection current_user: @user

    subscribe({})
    assert subscription.rejected?
  end

  test 'rejects unauthenticated subscription' do
    stub_connection current_user: nil

    subscribe(restaurant_id: @restaurant.id)
    assert subscription.rejected?
  end

  test 'streams only for the subscribed restaurant_id' do
    stub_connection current_user: @user

    subscribe(restaurant_id: @restaurant.id)

    assert_has_stream "floorplan:restaurant:#{@restaurant.id}"
    # Verify the stream name is exactly the one for this restaurant, not another.
    assert_not_includes subscription.streams, 'floorplan:restaurant:99999'
  end

  test 'unsubscribed does not raise' do
    stub_connection current_user: @user

    subscribe(restaurant_id: @restaurant.id)
    assert_nothing_raised { unsubscribe }
  end
end
