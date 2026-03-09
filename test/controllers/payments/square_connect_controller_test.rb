# frozen_string_literal: true

require 'test_helper'

class Payments::SquareConnectControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update!(user: @user)
    sign_in @user
  end

  # --- connect ---

  test 'connect redirects to Square OAuth when configured' do
    SquareConfig.stub :configured?, true do
      SquareConfig.stub :client_id, 'sandbox-sq0idp-test' do
        SquareConfig.stub :oauth_base_url, 'https://connect.squareupsandbox.com/oauth2' do
          get restaurant_payments_square_connect_path(@restaurant)
          assert_response :redirect
          assert_match %r{squareupsandbox\.com/oauth2/authorize}, response.location
          assert_match(/state=/, response.location)
        end
      end
    end
  end

  test 'connect shows alert when Square not configured' do
    SquareConfig.stub :configured?, false do
      get restaurant_payments_square_connect_path(@restaurant)
      assert_response :redirect
      assert_match(/not configured/, flash[:alert])
    end
  end

  test 'connect requires authentication' do
    sign_out @user
    get restaurant_payments_square_connect_path(@restaurant)
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  # --- callback ---

  test 'callback with error param redirects with alert' do
    get restaurant_payments_square_callback_path(@restaurant),
        params: { error: 'access_denied', error_description: 'User denied' }
    assert_response :redirect
    assert_match(/User denied/, flash[:alert])
  end

  test 'callback with mismatched state redirects with alert' do
    # Set a session state, then send a different one
    get restaurant_payments_square_callback_path(@restaurant),
        params: { code: 'auth-code', state: 'wrong-state' }
    assert_response :redirect
    assert_match(/Invalid OAuth state/, flash[:alert])
  end

  # --- disconnect ---

  test 'disconnect revokes and redirects' do
    ProviderAccount.create!(
      restaurant: @restaurant,
      provider: :square,
      access_token: 'tok',
      refresh_token: 'ref',
      status: :enabled,
      connected_at: 1.day.ago,
      environment: 'sandbox',
    )
    @restaurant.update!(payment_provider: 'square', payment_provider_status: :connected)

    # Get CSRF token
    get edit_restaurant_path(@restaurant, section: 'settings')
    csrf = response.body.to_s[/name="csrf-token" content="([^"]+)"/, 1]
    headers = {}
    headers['X-CSRF-Token'] = csrf if csrf.present?

    # Stub the HTTP call inside SquareConnect#revoke!
    HTTParty.stub :post, lambda { |*_args, **_opts|
      OpenStruct.new(success?: true, code: 200, parsed_response: { 'success' => true })
    } do
      delete restaurant_payments_square_disconnect_path(@restaurant), headers: headers
      assert_response :redirect
    end

    @restaurant.reload
    assert @restaurant.provider_disconnected?
  end

  # --- locations ---

  test 'locations redirects when not connected' do
    get restaurant_payments_square_locations_path(@restaurant)
    assert_response :redirect
    assert_match(/not connected/, flash[:alert])
  end

  # --- update_location ---

  test 'update_location saves location and redirects' do
    # Need CSRF token from a page visit
    get edit_restaurant_path(@restaurant, section: 'settings')
    csrf = response.body.to_s[/name="csrf-token" content="([^"]+)"/, 1]
    headers = {}
    headers['X-CSRF-Token'] = csrf if csrf.present?

    patch restaurant_payments_square_update_location_path(@restaurant),
          params: { location_id: 'LOC_ABC' },
          headers: headers
    assert_response :redirect
    @restaurant.reload
    assert_equal 'LOC_ABC', @restaurant.square_location_id
  end
end
