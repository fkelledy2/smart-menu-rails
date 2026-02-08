require 'test_helper'

class Payments::PaymentProfilesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def csrf_headers_for(restaurant)
    get edit_restaurant_path(restaurant, section: 'settings')
    csrf = response.body.to_s[/name="csrf-token" content="([^"]+)"/, 1]
    headers = {}
    headers['X-CSRF-Token'] = csrf if csrf.present?
    headers
  end

  test 'cannot set restaurant_mor unless Stripe provider account enabled' do
    user = users(:one)
    restaurant = restaurants(:one)
    restaurant.update!(user: user)

    sign_in user

    headers = csrf_headers_for(restaurant)

    patch restaurant_payments_payment_profile_path(restaurant), params: { payment_profile: { merchant_model: 'restaurant_mor' } }, headers: headers
    assert_response :redirect
  end

  test 'cannot set smartmenu_mor unless Stripe provider account enabled' do
    user = users(:one)
    restaurant = restaurants(:one)
    restaurant.update!(user: user)

    sign_in user

    headers = csrf_headers_for(restaurant)

    patch restaurant_payments_payment_profile_path(restaurant), params: { payment_profile: { merchant_model: 'smartmenu_mor' } }, headers: headers
    assert_response :redirect
  end

  test 'can set merchant_model when Stripe provider account enabled' do
    user = users(:one)
    restaurant = restaurants(:one)
    restaurant.update!(user: user)

    ProviderAccount.create!(
      restaurant: restaurant,
      provider: :stripe,
      provider_account_id: 'acct_test_1',
      status: :enabled,
    )

    sign_in user

    headers = csrf_headers_for(restaurant)

    patch restaurant_payments_payment_profile_path(restaurant), params: { payment_profile: { merchant_model: 'smartmenu_mor' } }, headers: headers
    assert_response :redirect

    assert_equal 'smartmenu_mor', restaurant.reload.payment_profile.merchant_model
  end
end
