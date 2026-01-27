require 'test_helper'
require 'ostruct'
require 'stripe'

class Payments::StripeConnectControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'start redirects to Stripe account onboarding link' do
    user = users(:one)
    restaurant = restaurants(:one)
    restaurant.update!(user: user)

    sign_in user

    prev_key = Stripe.api_key
    Stripe.api_key = 'sk_test_dummy'

    get edit_restaurant_path(restaurant, section: 'settings')
    csrf = response.body.to_s[/name=\"csrf-token\" content=\"([^\"]+)\"/, 1]

    headers = {}
    headers['X-CSRF-Token'] = csrf if csrf.present?

    Stripe::Account.stub(:create, OpenStruct.new(id: 'acct_123', type: 'express', country: 'US', default_currency: 'usd', capabilities: {}, payouts_enabled: false)) do
      Stripe::AccountLink.stub(:create, OpenStruct.new(url: 'https://connect.stripe.test/onboard')) do
        post restaurant_payments_stripe_connect_start_path(restaurant), headers: headers
        assert_response :redirect
        assert_equal 'https://connect.stripe.test/onboard', response.location
      end
    end
  ensure
    Stripe.api_key = prev_key
  end
end
