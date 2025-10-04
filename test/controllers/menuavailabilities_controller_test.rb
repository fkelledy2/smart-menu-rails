require 'test_helper'

class MenuavailabilitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @menuavailability = menuavailabilities(:one)
    @menu = menus(:one)
    @restaurant = restaurants(:one)
  end

  test 'should get index' do
    get restaurant_menu_menuavailabilities_url(@restaurant, @menu)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_menu_menuavailability_url(@restaurant, @menu)
    assert_response :success
  end

  #   test "should create menuavailability" do
  #     assert_difference("Menuavailability.count") do
  #       post menuavailabilities_url, params: { menuavailability: { dayofweek: @menuavailability.dayofweek, endhour: @menuavailability.endhour, endmin: @menuavailability.endmin, menu_id: @menuavailability.menu_id, starthour: @menuavailability.starthour, startmin: @menuavailability.startmin } }
  #     end
  #     assert_redirected_to edit_menu_url(@menuavailability.menu)
  #   end

  test 'should show menuavailability' do
    get restaurant_menu_menuavailability_url(@restaurant, @menu, @menuavailability)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_menu_menuavailability_url(@restaurant, @menu, @menuavailability)
    assert_response :success
  end

  test 'should update menuavailability' do
    patch restaurant_menu_menuavailability_url(@restaurant, @menu, @menuavailability),
          params: { menuavailability: { dayofweek: @menuavailability.dayofweek, endhour: @menuavailability.endhour,
                                        endmin: @menuavailability.endmin, menu_id: @menuavailability.menu_id, starthour: @menuavailability.starthour, startmin: @menuavailability.startmin, } }
    assert_response :success
  end

  test 'should destroy menuavailability' do
    assert_difference('Menuavailability.count', 0) do
      delete restaurant_menu_menuavailability_url(@restaurant, @menu, @menuavailability)
    end
    assert_response :success
  end
end
