# frozen_string_literal: true

require 'test_helper'

class TablesettingsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
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
end
