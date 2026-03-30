# frozen_string_literal: true

require 'test_helper'

class UserChannelTest < ActionCable::Channel::TestCase
  # UserChannel streams from "user_#{current_user.id}_channel".
  # Rejects if current_user is nil.

  def setup
    @user = users(:one)
  end

  test 'subscribes and streams for authenticated user' do
    stub_connection current_user: @user

    subscribe

    assert subscription.confirmed?
    assert_has_stream "user_#{@user.id}_channel"
  end

  test 'rejects subscription when current_user is nil' do
    stub_connection current_user: nil

    subscribe

    assert subscription.rejected?
  end

  test 'streams only on the subscribing user channel, not another user channel' do
    other_user = users(:two)
    stub_connection current_user: other_user

    subscribe

    assert_has_stream "user_#{other_user.id}_channel"
    assert_not_includes subscription.streams, "user_#{@user.id}_channel"
  end

  test 'unsubscribed does not raise' do
    stub_connection current_user: @user
    subscribe
    assert_nothing_raised { unsubscribe }
  end
end
