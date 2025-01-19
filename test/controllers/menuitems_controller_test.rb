require "test_helper"

class MenuitemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @menu = menus(:one)
    @restaurant = restaurants(:one)
    @menuitem = menuitems(:one)
    @menusection = menusections(:one)
    @menuitem.menusection = @menusection
    @menusection.menu = @menu
    @menu.restaurant = @restaurant
  end

  test "should get index" do
    get menuitems_url
    assert_response :success
  end

  test "should get new" do
    get new_menuitem_url, params: {menusection_id: @menusection.id }
    assert_response :success
  end

  test "should create menuitem" do
    assert_difference("Menuitem.count") do
      post menuitems_url, params: { menuitem: { calories: @menuitem.calories, description: @menuitem.description, image: @menuitem.image, menusection_id: @menuitem.menusection_id, name: @menuitem.name, price: @menuitem.price, sequence: @menuitem.sequence, status: @menuitem.status } }
    end
    assert_redirected_to edit_menusection_url(@menuitem.menusection)
  end

  test "should show menuitem" do
    get menuitem_url(@menuitem)
    assert_response :success
  end

  test "should get edit" do
    get edit_menuitem_url(@menuitem)
    assert_response :success
  end

  test "should update menuitem" do
    patch menuitem_url(@menuitem), params: { menuitem: { calories: @menuitem.calories, description: @menuitem.description, image: @menuitem.image, menusection_id: @menuitem.menusection_id, name: @menuitem.name, price: @menuitem.price, sequence: @menuitem.sequence, status: @menuitem.status } }
    assert_redirected_to edit_menusection_url(@menuitem.menusection)
  end

  test "should destroy menuitem" do
    assert_difference("Menuitem.count", 0) do
      delete menuitem_url(@menuitem)
    end
    assert_redirected_to edit_menusection_url(@menuitem.menusection)
  end
end
