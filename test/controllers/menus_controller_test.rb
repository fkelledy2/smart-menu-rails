require 'test_helper'

class MenusControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @menu = menus(:one)
    @restaurant = restaurants(:one)
  end

  test 'should get index' do
    get restaurant_menus_url(@restaurant)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_menu_url(@restaurant)
    assert_response :success
  end

  test 'should show menu' do
    get restaurant_menu_url(@restaurant, @menu)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_menu_url(@restaurant, @menu)
    assert_response :success
  end

  test 'should update menu' do
    patch restaurant_menu_url(@restaurant, @menu), params: { menu: {
      name: @menu.name,
      description: @menu.description,
      status: @menu.status,
      restaurant: @menu.restaurant,
      sequence: @menu.sequence,
      displayImages: @menu.displayImages,
      allowOrdering: @menu.allowOrdering,
      inventoryTracking: @menu.inventoryTracking,
      imagecontext: @menu.imagecontext,
    } }
    assert_response :success
  end

  test 'should destroy menu' do
    assert_difference('Menu.count', 0) do
      delete restaurant_menu_url(@restaurant, @menu)
    end
    #     assert_redirected_to edit_restaurant_url(@menu.restaurant)
  end
end
