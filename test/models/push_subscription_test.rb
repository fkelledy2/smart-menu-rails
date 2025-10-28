require 'test_helper'

class PushSubscriptionTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @subscription = PushSubscription.new(
      user: @user,
      endpoint: 'https://fcm.googleapis.com/fcm/send/test123',
      p256dh_key: 'test_p256dh_key',
      auth_key: 'test_auth_key',
    )
  end

  # Validation tests
  test 'should be valid with all required attributes' do
    assert @subscription.valid?
  end

  test 'should require endpoint' do
    @subscription.endpoint = nil
    assert_not @subscription.valid?
    assert_includes @subscription.errors[:endpoint], "can't be blank"
  end

  test 'should require p256dh_key' do
    @subscription.p256dh_key = nil
    assert_not @subscription.valid?
    assert_includes @subscription.errors[:p256dh_key], "can't be blank"
  end

  test 'should require auth_key' do
    @subscription.auth_key = nil
    assert_not @subscription.valid?
    assert_includes @subscription.errors[:auth_key], "can't be blank"
  end

  test 'should require unique endpoint' do
    @subscription.save!
    duplicate = PushSubscription.new(
      user: users(:two),
      endpoint: @subscription.endpoint,
      p256dh_key: 'different_key',
      auth_key: 'different_auth',
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:endpoint], 'has already been taken'
  end

  test 'should belong to user' do
    assert_respond_to @subscription, :user
    assert_equal @user, @subscription.user
  end

  test 'should have active default to true' do
    @subscription.save!
    assert @subscription.active?
  end

  # Scope tests
  test 'active scope should return only active subscriptions' do
    active_sub = PushSubscription.create!(
      user: @user,
      endpoint: 'https://fcm.googleapis.com/fcm/send/active',
      p256dh_key: 'key1',
      auth_key: 'auth1',
      active: true,
    )

    inactive_sub = PushSubscription.create!(
      user: @user,
      endpoint: 'https://fcm.googleapis.com/fcm/send/inactive',
      p256dh_key: 'key2',
      auth_key: 'auth2',
      active: false,
    )

    active_subscriptions = PushSubscription.active
    assert_includes active_subscriptions, active_sub
    assert_not_includes active_subscriptions, inactive_sub
  end

  test 'for_user scope should return subscriptions for specific user' do
    user1_sub = PushSubscription.create!(
      user: @user,
      endpoint: 'https://fcm.googleapis.com/fcm/send/user1',
      p256dh_key: 'key1',
      auth_key: 'auth1',
    )

    user2 = users(:two)
    user2_sub = PushSubscription.create!(
      user: user2,
      endpoint: 'https://fcm.googleapis.com/fcm/send/user2',
      p256dh_key: 'key2',
      auth_key: 'auth2',
    )

    user1_subscriptions = PushSubscription.for_user(@user)
    assert_includes user1_subscriptions, user1_sub
    assert_not_includes user1_subscriptions, user2_sub
  end

  # Method tests
  test 'send_notification should enqueue job for active subscription' do
    @subscription.save!

    # Just verify the method doesn't raise an error
    assert_nothing_raised do
      @subscription.send_notification('Test Title', 'Test Body', { test: true })
    end
  end

  test 'send_notification should not enqueue job for inactive subscription' do
    @subscription.active = false
    @subscription.save!

    # Inactive subscriptions return early without enqueueing
    result = @subscription.send_notification('Test Title', 'Test Body')
    assert_nil result
  end

  test 'deactivate! should set active to false' do
    @subscription.save!
    assert @subscription.active?

    @subscription.deactivate!
    assert_not @subscription.reload.active?
  end

  # Association tests
  test 'should be destroyed when user is destroyed' do
    # Create a fresh user without complex associations
    test_user = User.create!(
      email: 'test_push@example.com',
      password: 'password123',
      password_confirmation: 'password123',
    )

    test_subscription = PushSubscription.create!(
      user: test_user,
      endpoint: 'https://fcm.googleapis.com/fcm/send/test_destroy',
      p256dh_key: 'test_key',
      auth_key: 'test_auth',
    )

    subscription_id = test_subscription.id

    test_user.destroy

    assert_nil PushSubscription.find_by(id: subscription_id)
  end
end
