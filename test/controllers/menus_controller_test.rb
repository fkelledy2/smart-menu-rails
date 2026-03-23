# frozen_string_literal: true

require 'test_helper'

class MenusControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
    @menu = menus(:one)
  end

  test 'GET index succeeds anonymously' do
    get restaurant_menus_path(@restaurant)
    assert_response :success
  end

  test 'GET index succeeds for restaurant owner' do
    sign_in users(:one)
    get restaurant_menus_path(@restaurant)
    assert_response :success
  end

  test 'GET new redirects unauthenticated' do
    get new_restaurant_menu_path(@restaurant)
    assert_redirected_to new_user_session_path
  end

  test 'GET new succeeds for restaurant owner' do
    sign_in users(:one)
    get new_restaurant_menu_path(@restaurant)
    assert_response :success
  end
end
