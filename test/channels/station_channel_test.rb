# frozen_string_literal: true

require 'test_helper'

class StationChannelTest < ActionCable::Channel::TestCase
  # StationChannel:
  #   - Requires restaurant_id AND station params.
  #   - station must be 'kitchen' or 'bar'.
  #   - Streams from "#{station}_#{restaurant_id}".
  #   - Calls PresenceService.user_online when current_user is present.
  #   - Calls PresenceService.user_offline on unsubscribe when current_user is present.

  def setup
    @user       = users(:one)
    @restaurant = restaurants(:one)
  end

  # ---------------------------------------------------------------------------
  # Successful subscription — kitchen
  # ---------------------------------------------------------------------------

  test 'subscribes to kitchen station and confirms' do
    stub_connection current_user: @user

    subscribe(restaurant_id: @restaurant.id, station: 'kitchen')

    assert subscription.confirmed?
    assert_has_stream "kitchen_#{@restaurant.id}"
  end

  # ---------------------------------------------------------------------------
  # Successful subscription — bar
  # ---------------------------------------------------------------------------

  test 'subscribes to bar station and confirms' do
    stub_connection current_user: @user

    subscribe(restaurant_id: @restaurant.id, station: 'bar')

    assert subscription.confirmed?
    assert_has_stream "bar_#{@restaurant.id}"
  end

  # ---------------------------------------------------------------------------
  # Rejection cases
  # ---------------------------------------------------------------------------

  test 'rejects when restaurant_id is missing' do
    stub_connection current_user: @user

    subscribe(station: 'kitchen')

    assert subscription.rejected?
  end

  test 'rejects when station param is missing' do
    stub_connection current_user: @user

    subscribe(restaurant_id: @restaurant.id)

    assert subscription.rejected?
  end

  test 'rejects when station is not kitchen or bar' do
    stub_connection current_user: @user

    subscribe(restaurant_id: @restaurant.id, station: 'lounge')

    assert subscription.rejected?
  end

  # ---------------------------------------------------------------------------
  # Unauthenticated client — must be rejected since kitchen/bar streams contain
  # order data that should not be exposed to anonymous connections.
  # ---------------------------------------------------------------------------

  test 'rejects unauthenticated client (no current_user)' do
    stub_connection current_user: nil

    subscribe(restaurant_id: @restaurant.id, station: 'bar')

    assert subscription.rejected?
  end

  # ---------------------------------------------------------------------------
  # PresenceService integration
  # ---------------------------------------------------------------------------

  test 'calls PresenceService.user_online when current_user is present' do
    stub_connection current_user: @user

    presence_called = false
    PresenceService.stub(:user_online, ->(*_args, **_kwargs) { presence_called = true }) do
      subscribe(restaurant_id: @restaurant.id, station: 'kitchen')
    end

    assert presence_called, 'PresenceService.user_online should be called on subscribe'
  end

  test 'does not call PresenceService.user_online when current_user is nil (rejects subscription)' do
    stub_connection current_user: nil

    presence_called = false
    PresenceService.stub(:user_online, ->(*_args, **_kwargs) { presence_called = true }) do
      subscribe(restaurant_id: @restaurant.id, station: 'kitchen')
    end

    assert subscription.rejected?
    assert_not presence_called
  end

  test 'calls PresenceService.user_offline on unsubscribe when current_user is present' do
    stub_connection current_user: @user

    offline_called = false
    PresenceService.stub(:user_online, ->(*_args, **_kwargs) {}) do
      subscribe(restaurant_id: @restaurant.id, station: 'kitchen')
    end

    PresenceService.stub(:user_offline, ->(*_args, **_kwargs) { offline_called = true }) do
      unsubscribe
    end

    assert offline_called, 'PresenceService.user_offline should be called on unsubscribe'
  end
end
