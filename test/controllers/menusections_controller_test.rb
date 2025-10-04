require 'test_helper'

class MenusectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @menusection = menusections(:one)
    @menu = menus(:one)
    @restaurant = restaurants(:one)
  end

  test 'should get index' do
    get restaurant_menu_menusections_url(@restaurant, @menu)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_menu_menusection_url(@restaurant, @menu)
    assert_response :success
  end

  #   test "should create menusection" do
  #     assert_difference("Menusection.count") do
  #       post menusections_url, params: { menusection: { description: @menusection.description, image: @menusection.image, menu_id: @menusection.menu_id, name: @menusection.name, sequence: @menusection.sequence, status: @menusection.status } }
  #     end
  #     assert_redirected_to edit_menu_url(@menusection.menu)
  #   end

  test 'should show menusection' do
    get restaurant_menu_menusection_url(@restaurant, @menu, @menusection)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_menu_menusection_url(@restaurant, @menu, @menusection)
    assert_response :success
  end

  test 'should update menusection' do
    patch restaurant_menu_menusection_url(@restaurant, @menu, @menusection),
          params: { menusection: { description: @menusection.description, image: @menusection.image,
                                   menu_id: @menusection.menu_id, name: @menusection.name, sequence: @menusection.sequence, status: @menusection.status, } }
    assert_response :success
  end

  test 'should destroy menusection' do
    assert_difference('Menusection.count', 0) do
      delete restaurant_menu_menusection_url(@restaurant, @menu, @menusection)
    end
    assert_response :success
  end
end
