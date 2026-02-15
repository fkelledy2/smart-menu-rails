require 'test_helper'

class PushNotificationServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @subscription = PushSubscription.create!(
      user: @user,
      endpoint: 'https://fcm.googleapis.com/fcm/send/test',
      p256dh_key: 'test_key',
      auth_key: 'test_auth',
      active: true,
    )
  end

  test "send_to_user should send notification to user's subscriptions" do
    count = PushNotificationService.send_to_user(
      @user,
      'Test Title',
      'Test Body',
      { test: true },
    )

    assert_equal 1, count
  end

  test 'send_to_user should return 0 for user with no subscriptions' do
    user_without_subs = users(:two)

    count = PushNotificationService.send_to_user(
      user_without_subs,
      'Test Title',
      'Test Body',
    )

    assert_equal 0, count
  end

  test 'send_to_user should handle nil user' do
    count = PushNotificationService.send_to_user(
      nil,
      'Test Title',
      'Test Body',
    )

    assert_nil count
  end

  test 'send_to_user should only send to active subscriptions' do
    PushSubscription.create!(
      user: @user,
      endpoint: 'https://fcm.googleapis.com/fcm/send/inactive',
      p256dh_key: 'key2',
      auth_key: 'auth2',
      active: false,
    )

    count = PushNotificationService.send_to_user(
      @user,
      'Test Title',
      'Test Body',
    )

    # Should only count the active subscription
    assert_equal 1, count
  end

  test 'send_to_users should send to multiple users' do
    user2 = users(:two)
    PushSubscription.create!(
      user: user2,
      endpoint: 'https://fcm.googleapis.com/fcm/send/user2',
      p256dh_key: 'key2',
      auth_key: 'auth2',
    )

    count = PushNotificationService.send_to_users(
      [@user, user2],
      'Test Title',
      'Test Body',
    )

    assert_equal 2, count
  end

  test 'send_order_update should send notification with order data' do
    restaurant = restaurants(:one)
    restaurant.update!(user: @user)

    # Use existing fixtures that have all required associations
    order = ordrs(:one)
    order.restaurant.update!(user: @user)

    count = PushNotificationService.send_order_update(
      order,
      'Your order is ready',
    )

    assert_equal 1, count
  end

  # NOTE: send_order_update test for order without user removed —
  # Ordr model requires user association, making this scenario impossible.

  test 'send_menu_update should send notification with menu data' do
    restaurant = restaurants(:one)
    restaurant.update!(user: @user)

    menu = Menu.create!(
      restaurant: restaurant,
      name: 'Test Menu',
      status: :active,
    )

    count = PushNotificationService.send_menu_update(
      menu,
      'Menu has been updated',
    )

    assert_equal 1, count
  end

  test 'send_kitchen_notification should send to restaurant owner' do
    restaurant = restaurants(:one)
    restaurant.update!(user: @user)

    count = PushNotificationService.send_kitchen_notification(
      restaurant,
      'New order received',
      { order_id: 123 },
    )

    assert_equal 1, count
  end

  test 'send_test_notification should send test message' do
    count = PushNotificationService.send_test_notification(@user)

    assert_equal 1, count
  end
end
