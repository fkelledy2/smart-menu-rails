# frozen_string_literal: true

require 'test_helper'

class TablesettingsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
    @tablesetting = tablesettings(:table_one)
  end

  test 'GET index succeeds for restaurant owner' do
    sign_in users(:one)
    get restaurant_tablesettings_path(@restaurant)
    assert_response :success
  end

  test 'GET new redirects unauthenticated' do
    get new_restaurant_tablesetting_path(@restaurant)
    assert_redirected_to new_user_session_path
  end

  test 'GET new succeeds for authenticated user' do
    sign_in users(:one)
    get new_restaurant_tablesetting_path(@restaurant)
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # regenerate_qr
  # ---------------------------------------------------------------------------

  test 'POST regenerate_qr requires authentication' do
    post regenerate_qr_restaurant_tablesetting_path(@restaurant, @tablesetting)
    assert_redirected_to new_user_session_path
  end

  test 'POST regenerate_qr rotates tokens for all smartmenus linked to the table' do
    sign_in users(:one)
    sm = smartmenus(:one)
    old_token = sm.public_token

    post regenerate_qr_restaurant_tablesetting_path(@restaurant, @tablesetting)

    assert_response :redirect
    assert_not_equal old_token, sm.reload.public_token
  end

  test 'POST regenerate_qr deactivates active dining sessions for that table' do
    sign_in users(:one)

    ds = DiningSession.create!(
      smartmenu: smartmenus(:one),
      tablesetting: @tablesetting,
      restaurant: @restaurant,
      session_token: SecureRandom.hex(32),
    )
    assert ds.active?

    post regenerate_qr_restaurant_tablesetting_path(@restaurant, @tablesetting)

    assert_not ds.reload.active?
  end

  test 'POST regenerate_qr is forbidden for non-owner' do
    sign_in users(:two)
    post regenerate_qr_restaurant_tablesetting_path(@restaurant, @tablesetting)
    assert_response :redirect # redirected by Pundit with flash
  end

  test 'POST regenerate_qr returns JSON ok status for JSON requests' do
    sign_in users(:one)
    post regenerate_qr_restaurant_tablesetting_path(@restaurant, @tablesetting),
         headers: { 'Accept' => 'application/json' }
    assert_response :success
    json = response.parsed_body
    assert_equal 'ok', json['status']
  end
end
