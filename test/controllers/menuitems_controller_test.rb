require 'test_helper'

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

  test 'should get index' do
    get restaurant_menu_menusection_menuitems_url(@restaurant, @menu, @menusection)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_menu_menusection_menuitem_url(@restaurant, @menu, @menusection)
    assert_response :success
  end

  #   test "should create menuitem" do
  #     assert_difference("Menuitem.count") do
  #     end
  #     assert_redirected_to edit_menusection_url(@menuitem.menusection)
  #   end

  test 'should show menuitem' do
    get restaurant_menu_menusection_menuitem_url(@restaurant, @menu, @menusection, @menuitem)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_menu_menusection_menuitem_url(@restaurant, @menu, @menusection, @menuitem)
    assert_response :success
  end

  test 'should update menuitem' do
    patch restaurant_menu_menusection_menuitem_url(@restaurant, @menu, @menusection, @menuitem),
          params: { menuitem: { description: @menuitem.description, image: @menuitem.image,
                                menusection_id: @menuitem.menusection_id, name: @menuitem.name, price: @menuitem.price, sequence: @menuitem.sequence, status: @menuitem.status, } }
    assert_response :success
  end

  test 'should destroy menuitem' do
    assert_difference('Menuitem.count', 0) do
      delete restaurant_menu_menusection_menuitem_url(@restaurant, @menu, @menusection, @menuitem)
    end
    assert_response :success
  end
end
