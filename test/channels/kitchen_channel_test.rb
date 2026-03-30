# frozen_string_literal: true

require 'test_helper'

class KitchenChannelTest < ActionCable::Channel::TestCase
  # KitchenChannel:
  #   - Rejects when restaurant_id param is missing.
  #   - Streams from "kitchen_#{restaurant_id}" regardless of auth.
  #   - Calls PresenceService.user_online when current_user is present.
  #   - Calls PresenceService.user_offline on unsubscribe when current_user is present.
  #   - receive('update_status') requires current_user; ignores unauthenticated clients.

  def setup
    @user       = users(:one)
    @restaurant = restaurants(:one)
  end

  # ---------------------------------------------------------------------------
  # Subscription — authenticated
  # ---------------------------------------------------------------------------

  test 'subscribes and streams when restaurant_id is provided' do
    stub_connection current_user: @user

    subscribe(restaurant_id: @restaurant.id)

    assert subscription.confirmed?
    assert_has_stream "kitchen_#{@restaurant.id}"
  end

  test 'subscribes without current_user (unauthenticated, display-only client)' do
    stub_connection current_user: nil

    subscribe(restaurant_id: @restaurant.id)

    assert subscription.confirmed?
    assert_has_stream "kitchen_#{@restaurant.id}"
  end

  # ---------------------------------------------------------------------------
  # Rejection
  # ---------------------------------------------------------------------------

  test 'rejects when restaurant_id param is missing' do
    stub_connection current_user: @user

    subscribe({})

    assert subscription.rejected?
  end

  test 'rejects when restaurant_id is nil' do
    stub_connection current_user: @user

    subscribe(restaurant_id: nil)

    assert subscription.rejected?
  end

  # ---------------------------------------------------------------------------
  # Presence tracking
  # ---------------------------------------------------------------------------

  test 'calls PresenceService.user_online on subscribe when current_user present' do
    stub_connection current_user: @user

    presence_called = false
    PresenceService.stub(:user_online, ->(*_args, **_kwargs) { presence_called = true }) do
      subscribe(restaurant_id: @restaurant.id)
    end

    assert presence_called, 'PresenceService.user_online should be called'
  end

  test 'does not call PresenceService.user_online when current_user is nil' do
    stub_connection current_user: nil

    presence_called = false
    PresenceService.stub(:user_online, ->(*_args, **_kwargs) { presence_called = true }) do
      subscribe(restaurant_id: @restaurant.id)
    end

    assert_not presence_called
  end

  test 'calls PresenceService.user_offline on unsubscribe when current_user is present' do
    stub_connection current_user: @user

    PresenceService.stub(:user_online, ->(*_args, **_kwargs) {}) do
      subscribe(restaurant_id: @restaurant.id)
    end

    offline_called = false
    PresenceService.stub(:user_offline, ->(*_args, **_kwargs) { offline_called = true }) do
      unsubscribe
    end

    assert offline_called, 'PresenceService.user_offline should be called on unsubscribe'
  end

  test 'does not call PresenceService.user_offline when current_user is nil on unsubscribe' do
    stub_connection current_user: nil

    subscribe(restaurant_id: @restaurant.id)

    offline_called = false
    PresenceService.stub(:user_offline, ->(*_args, **_kwargs) { offline_called = true }) do
      unsubscribe
    end

    assert_not offline_called
  end

  # ---------------------------------------------------------------------------
  # receive — update_status action (requires current_user)
  # ---------------------------------------------------------------------------

  test 'receive update_status does not raise when current_user is nil' do
    stub_connection current_user: nil

    subscribe(restaurant_id: @restaurant.id)

    assert_nothing_raised do
      perform :receive, { 'action' => 'update_status', 'order_id' => 9_999_999, 'new_status' => '20' }
    end
  end

  test 'receive update_status does not raise when order is not found' do
    stub_connection current_user: @user

    subscribe(restaurant_id: @restaurant.id)

    assert_nothing_raised do
      perform :receive, { 'action' => 'update_status', 'order_id' => 9_999_999, 'new_status' => '20' }
    end
  end

  # ---------------------------------------------------------------------------
  # receive — assign_staff action
  # ---------------------------------------------------------------------------

  test 'receive assign_staff does not raise when current_user is nil' do
    stub_connection current_user: nil

    subscribe(restaurant_id: @restaurant.id)

    assert_nothing_raised do
      perform :receive, { 'action' => 'assign_staff', 'order_id' => 9_999_999, 'staff_id' => 9_999_999 }
    end
  end

  # ---------------------------------------------------------------------------
  # unsubscribe does not raise
  # ---------------------------------------------------------------------------

  test 'unsubscribed does not raise' do
    stub_connection current_user: @user

    PresenceService.stub(:user_online, ->(*_args, **_kwargs) {}) do
      subscribe(restaurant_id: @restaurant.id)
    end

    PresenceService.stub(:user_offline, ->(*_args, **_kwargs) {}) do
      assert_nothing_raised { unsubscribe }
    end
  end
end
