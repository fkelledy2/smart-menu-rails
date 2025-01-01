require "test_helper"

class MenusControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @menu = menus(:one)
  end

  test "should get index" do
    get menus_url
    assert_response :success
  end

  test "should get new" do
    get new_menu_url
    assert_response :success
  end

  test "should create menu" do
    assert_difference("Menu.count") do
      post menus_url, params: { menu: { description: @menu.description, image: @menu.image, name: @menu.name, restaurant_id: @menu.restaurant_id, sequence: @menu.sequence, status: @menu.status } }
    end
    assert_redirected_to edit_restaurant_url(@menu.restaurant)
  end

  test "should show menu" do
    get menu_url(@menu)
    assert_response :success
  end

  test "should get edit" do
    get edit_menu_url(@menu)
    assert_response :success
  end

  test "should update menu" do
    patch menu_url(@menu), params: { menu: { description: @menu.description, image: @menu.image, name: @menu.name, restaurant_id: @menu.restaurant_id, sequence: @menu.sequence, status: @menu.status } }
    assert_redirected_to edit_restaurant_url(@menu.restaurant)
  end

  test "should destroy menu" do
    assert_difference("Menu.count", 0) do
      delete menu_url(@menu)
    end
    assert_redirected_to edit_restaurants_url(@menu.restaurant)
  end
end
