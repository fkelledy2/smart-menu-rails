require "test_helper"

class MenusControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @menu = menus(:one)
    @restaurant = restaurants(:one)
  end

  test "should get index" do
    get menus_url
    assert_response :success
  end

  test "should get new" do
    get new_menu_url, params: { restaurant_id: @restaurant.id }
    assert_response :success
  end

  test "should create menu" do
    assert_difference("Menu.count") do
      post menus_url, params: { menu: {
        name: @menu.name,
        description: @menu.description,
        status: @menu.status,
        restaurant_id: @restaurant.id,
        sequence: @menu.sequence,
        displayImages: @menu.displayImages,
        allowOrdering: @menu.allowOrdering,
        inventoryTracking: @menu.inventoryTracking,
        imagecontext: @menu.imagecontext
      } }
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
    patch menu_url(@menu), params: { menu: {
        name: @menu.name,
        description: @menu.description,
        status: @menu.status,
        restaurant: @menu.restaurant,
        sequence: @menu.sequence,
        displayImages: @menu.displayImages,
        allowOrdering: @menu.allowOrdering,
        inventoryTracking: @menu.inventoryTracking,
        imagecontext: @menu.imagecontext
    } }
#     assert_redirected_to edit_restaurant_url(@menu.restaurant)
  end

  test "should destroy menu" do
    assert_difference("Menu.count", 0) do
      delete menu_url(@menu)
    end
    assert_redirected_to edit_restaurant_url(@menu.restaurant)
  end
end
