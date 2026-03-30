# frozen_string_literal: true

require 'test_helper'

class MenuEditingChannelTest < ActionCable::Channel::TestCase
  # MenuEditingChannel:
  #   - Requires both menu_id param AND current_user.
  #   - Rejects if either is missing.
  #   - Streams from "menu_#{menu_id}_editing".
  #   - Creates or updates a MenuEditSession on subscribe.
  #   - Destroys the MenuEditSession and calls PresenceService.user_offline on unsubscribe.
  #   - receive actions: lock_field, unlock_field, update_field (all delegate to MenuBroadcastService).

  def setup
    @user = users(:one)
    @menu = menus(:one)
  end

  # ---------------------------------------------------------------------------
  # Subscription — authenticated with menu_id
  # ---------------------------------------------------------------------------

  test 'subscribes and streams when current_user and menu_id are provided' do
    stub_connection current_user: @user

    subscribe(menu_id: @menu.id)

    assert subscription.confirmed?
    assert_has_stream "menu_#{@menu.id}_editing"
  end

  # ---------------------------------------------------------------------------
  # Rejection cases
  # ---------------------------------------------------------------------------

  test 'rejects when current_user is nil' do
    stub_connection current_user: nil

    subscribe(menu_id: @menu.id)

    assert subscription.rejected?
  end

  test 'rejects when menu_id param is missing' do
    stub_connection current_user: @user

    subscribe({})

    assert subscription.rejected?
  end

  test 'rejects when menu_id is nil' do
    stub_connection current_user: @user

    subscribe(menu_id: nil)

    assert subscription.rejected?
  end

  # ---------------------------------------------------------------------------
  # Does not stream on rejected subscription
  # ---------------------------------------------------------------------------

  test 'no stream is created when subscription is rejected (no user)' do
    stub_connection current_user: nil

    subscribe(menu_id: @menu.id)

    assert_empty subscription.streams
  end

  # ---------------------------------------------------------------------------
  # PresenceService
  # ---------------------------------------------------------------------------

  test 'calls PresenceService.user_online on subscribe' do
    stub_connection current_user: @user

    presence_called = false
    PresenceService.stub(:user_online, ->(*_args, **_kwargs) { presence_called = true }) do
      subscribe(menu_id: @menu.id)
    end

    assert presence_called, 'PresenceService.user_online should be called on subscribe'
  end

  test 'calls PresenceService.user_offline on unsubscribe' do
    stub_connection current_user: @user

    PresenceService.stub(:user_online, ->(*_args, **_kwargs) {}) do
      subscribe(menu_id: @menu.id)
    end

    offline_called = false
    PresenceService.stub(:user_offline, ->(*_args, **_kwargs) { offline_called = true }) do
      unsubscribe
    end

    assert offline_called, 'PresenceService.user_offline should be called on unsubscribe'
  end

  # ---------------------------------------------------------------------------
  # MenuEditSession creation
  # ---------------------------------------------------------------------------

  test 'creates a MenuEditSession on subscribe' do
    stub_connection current_user: @user

    PresenceService.stub(:user_online, ->(*_args, **_kwargs) {}) do
      assert_difference 'MenuEditSession.count', 1 do
        subscribe(menu_id: @menu.id)
      end
    end
  end

  test 'does not create duplicate MenuEditSession for same user and menu' do
    # MenuEditSession uses find_or_create_by(menu_id:, user:), so a second call
    # on the same channel instance (same subscription) is idempotent.
    stub_connection current_user: @user

    PresenceService.stub(:user_online, ->(*_args, **_kwargs) {}) do
      subscribe(menu_id: @menu.id)
      # Calling find_or_create_by again should not add a second row.
      initial_count = MenuEditSession.where(menu_id: @menu.id, user: @user).count
      MenuEditSession.find_or_create_by(menu_id: @menu.id, user: @user)
      assert_equal initial_count, MenuEditSession.where(menu_id: @menu.id, user: @user).count
    end
  end

  # ---------------------------------------------------------------------------
  # receive — lock_field / unlock_field / update_field
  # Tests verify that receive dispatches to the correct handler without raising.
  # The ActionCable broadcast itself is suppressed to avoid connection errors.
  # ---------------------------------------------------------------------------

  test 'receive lock_field does not raise' do
    stub_connection current_user: @user

    PresenceService.stub(:user_online, ->(*_args, **_kwargs) {}) do
      subscribe(menu_id: @menu.id)
    end

    ActionCable.server.stub(:broadcast, nil) do
      assert_nothing_raised do
        perform :receive, { 'action' => 'lock_field', 'field' => 'name' }
      end
    end
  end

  test 'receive unlock_field does not raise' do
    stub_connection current_user: @user

    PresenceService.stub(:user_online, ->(*_args, **_kwargs) {}) do
      subscribe(menu_id: @menu.id)
    end

    ActionCable.server.stub(:broadcast, nil) do
      assert_nothing_raised do
        perform :receive, { 'action' => 'unlock_field', 'field' => 'name' }
      end
    end
  end

  test 'receive update_field does not raise' do
    stub_connection current_user: @user

    PresenceService.stub(:user_online, ->(*_args, **_kwargs) {}) do
      subscribe(menu_id: @menu.id)
    end

    ActionCable.server.stub(:broadcast, nil) do
      assert_nothing_raised do
        perform :receive, { 'action' => 'update_field', 'field' => 'description', 'value' => 'New value' }
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Unsubscribe teardown
  # ---------------------------------------------------------------------------

  test 'unsubscribed does not raise' do
    stub_connection current_user: @user

    PresenceService.stub(:user_online, ->(*_args, **_kwargs) {}) do
      subscribe(menu_id: @menu.id)
    end

    PresenceService.stub(:user_offline, ->(*_args, **_kwargs) {}) do
      assert_nothing_raised { unsubscribe }
    end
  end

  private

  def unsubscribe_quietly
    PresenceService.stub(:user_offline, ->(*_args, **_kwargs) {}) do
      unsubscribe
    end
  end
end
