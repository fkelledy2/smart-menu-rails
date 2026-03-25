# frozen_string_literal: true

require 'test_helper'

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test 'POST create redirects unauthenticated' do
    post push_subscriptions_path, params: {
      subscription: { endpoint: 'https://example.com', p256dh_key: 'key', auth_key: 'auth' },
    }, as: :json
    assert_response :unauthorized
  end

  test 'POST test redirects unauthenticated' do
    post push_subscription_probe_path, as: :json
    assert_response :unauthorized
  end

  test 'POST create creates subscription for authenticated user' do
    sign_in users(:one)
    post push_subscriptions_path, params: {
      subscription: {
        endpoint: 'https://fcm.googleapis.com/fcm/send/test-endpoint',
        p256dh_key: 'BNcRdreALRFXTkOOUHK1EtK2wtZ5MqEbFcQhxI33DJQ',
        auth_key: 'tBHItJI5svbpez7KI4CCXg==',
      },
    }, as: :json
    assert_response :created
  end
end
