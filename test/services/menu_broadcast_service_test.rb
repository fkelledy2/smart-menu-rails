require 'test_helper'

class MenuBroadcastServiceTest < ActiveSupport::TestCase
  setup do
    @menu = menus(:one)
    @user = users(:one)
    @changes = { name: ['Old Name', 'New Name'] }
  end

  test 'broadcasts menu change' do
    assert_nothing_raised do
      MenuBroadcastService.broadcast_menu_change(@menu, @changes, @user)
    end
  end

  test 'broadcasts field lock' do
    assert_nothing_raised do
      MenuBroadcastService.broadcast_field_lock(@menu, 'name', @user)
    end
  end

  test 'broadcasts field unlock' do
    assert_nothing_raised do
      MenuBroadcastService.broadcast_field_unlock(@menu, 'name', @user)
    end
  end

  test 'broadcast_menu_change includes event type' do
    # Mock ActionCable to capture broadcast data
    broadcast_data = nil
    ActionCable.server.stub(:broadcast, ->(channel, data) { broadcast_data = data }) do
      MenuBroadcastService.broadcast_menu_change(@menu, @changes, @user)
    end

    assert_equal 'menu_change', broadcast_data[:event]
  end

  test 'broadcast_menu_change includes menu_id' do
    broadcast_data = nil
    ActionCable.server.stub(:broadcast, ->(channel, data) { broadcast_data = data }) do
      MenuBroadcastService.broadcast_menu_change(@menu, @changes, @user)
    end

    assert_equal @menu.id, broadcast_data[:menu_id]
  end

  test 'broadcast_menu_change includes changes' do
    broadcast_data = nil
    ActionCable.server.stub(:broadcast, ->(channel, data) { broadcast_data = data }) do
      MenuBroadcastService.broadcast_menu_change(@menu, @changes, @user)
    end

    assert_equal @changes, broadcast_data[:changes]
  end

  test 'broadcast_menu_change includes user information' do
    broadcast_data = nil
    ActionCable.server.stub(:broadcast, ->(channel, data) { broadcast_data = data }) do
      MenuBroadcastService.broadcast_menu_change(@menu, @changes, @user)
    end

    assert_equal @user.id, broadcast_data[:user][:id]
    assert_equal @user.email, broadcast_data[:user][:email]
  end

  test 'broadcast_menu_change includes timestamp' do
    broadcast_data = nil
    ActionCable.server.stub(:broadcast, ->(channel, data) { broadcast_data = data }) do
      MenuBroadcastService.broadcast_menu_change(@menu, @changes, @user)
    end

    assert_not_nil broadcast_data[:timestamp]
    assert_kind_of String, broadcast_data[:timestamp]
  end

  test 'broadcast_field_lock includes event type' do
    broadcast_data = nil
    ActionCable.server.stub(:broadcast, ->(channel, data) { broadcast_data = data }) do
      MenuBroadcastService.broadcast_field_lock(@menu, 'name', @user)
    end

    assert_equal 'field_locked', broadcast_data[:event]
  end

  test 'broadcast_field_lock includes field name' do
    broadcast_data = nil
    ActionCable.server.stub(:broadcast, ->(channel, data) { broadcast_data = data }) do
      MenuBroadcastService.broadcast_field_lock(@menu, 'description', @user)
    end

    assert_equal 'description', broadcast_data[:field]
  end

  test 'broadcast_field_unlock includes event type' do
    broadcast_data = nil
    ActionCable.server.stub(:broadcast, ->(channel, data) { broadcast_data = data }) do
      MenuBroadcastService.broadcast_field_unlock(@menu, 'name', @user)
    end

    assert_equal 'field_unlocked', broadcast_data[:event]
  end

  test 'uses correct channel name for menu' do
    channel_name = nil
    ActionCable.server.stub(:broadcast, ->(channel, _data) { channel_name = channel }) do
      MenuBroadcastService.broadcast_menu_change(@menu, @changes, @user)
    end

    assert_equal "menu_#{@menu.id}_editing", channel_name
  end

  test 'handles empty changes' do
    assert_nothing_raised do
      MenuBroadcastService.broadcast_menu_change(@menu, {}, @user)
    end
  end

  test 'handles nil field in lock' do
    assert_nothing_raised do
      MenuBroadcastService.broadcast_field_lock(@menu, nil, @user)
    end
  end

  test 'handles nil field in unlock' do
    assert_nothing_raised do
      MenuBroadcastService.broadcast_field_unlock(@menu, nil, @user)
    end
  end
end
