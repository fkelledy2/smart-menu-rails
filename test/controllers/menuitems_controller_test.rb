# frozen_string_literal: true

require 'test_helper'

class MenuitemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @menusection = menusections(:one)
    @menuitem = menuitems(:one)
  end

  test 'GET index redirects unauthenticated' do
    get restaurant_menu_menusection_menuitems_path(@restaurant, @menu, @menusection)
    assert_redirected_to new_user_session_path
  end

  test 'GET index succeeds for restaurant owner as JSON' do
    sign_in users(:one)
    get restaurant_menu_menusection_menuitems_path(@restaurant, @menu, @menusection), as: :json
    assert_response :success
  end

  test 'GET new redirects unauthenticated' do
    get new_restaurant_menu_menusection_menuitem_path(@restaurant, @menu, @menusection)
    assert_redirected_to new_user_session_path
  end

  test 'GET new succeeds for restaurant owner' do
    sign_in users(:one)
    get new_restaurant_menu_menusection_menuitem_path(@restaurant, @menu, @menusection)
    assert_response :success
  end
end
