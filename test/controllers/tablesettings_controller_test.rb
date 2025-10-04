require 'test_helper'

class TablesettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @tablesetting = tablesettings(:one)
    @restaurant = restaurants(:one)
  end

  test 'should get index' do
    get restaurant_tablesettings_url(@restaurant)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_tablesetting_url(@restaurant)
    assert_response :success
  end

  #   test "should create tablesetting" do
  #     assert_difference("Tablesetting.count") do
  #       post tablesettings_url, params: { tablesetting: { tabletype: @tablesetting.tabletype, capacity: @tablesetting.capacity, description: @tablesetting.description, name: @tablesetting.name, restaurant_id: @tablesetting.restaurant_id, status: @tablesetting.status } }
  #     end
  #     assert_redirected_to edit_restaurant_url(@tablesetting.restaurant)
  #   end

  test 'should show tablesetting' do
    get restaurant_tablesetting_url(@restaurant, @tablesetting)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_tablesetting_url(@restaurant, @tablesetting)
    assert_response :success
  end

  test 'should update tablesetting' do
    patch restaurant_tablesetting_url(@restaurant, @tablesetting),
          params: { tablesetting: { capacity: @tablesetting.capacity, name: @tablesetting.name,
                                    restaurant_id: @tablesetting.restaurant_id, } }
    assert_response :success
  end

  test 'should destroy tablesetting' do
    assert_difference('Tablesetting.count', 0) do
      delete restaurant_tablesetting_url(@restaurant, @tablesetting)
    end
    assert_response :success
  end
end
