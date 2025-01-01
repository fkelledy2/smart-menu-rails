require "test_helper"

class TablesettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @tablesetting = tablesettings(:one)
  end

  test "should get index" do
    get tablesettings_url
    assert_response :success
  end

  test "should get new" do
    get new_tablesetting_url
    assert_response :success
  end

  test "should create tablesetting" do
    assert_difference("Tablesetting.count") do
      post tablesettings_url, params: { tablesetting: { capacity: @tablesetting.capacity, description: @tablesetting.description, name: @tablesetting.name, restaurant_id: @tablesetting.restaurant_id, status: @tablesetting.status } }
    end
    assert_redirected_to edit_restaurant_url(@tablesetting.restaurant)
  end

  test "should show tablesetting" do
    get tablesetting_url(@tablesetting)
    assert_response :success
  end

  test "should get edit" do
    get edit_tablesetting_url(@tablesetting)
    assert_response :success
  end

  test "should update tablesetting" do
    patch tablesetting_url(@tablesetting), params: { tablesetting: { capacity: @tablesetting.capacity, description: @tablesetting.description, name: @tablesetting.name, restaurant_id: @tablesetting.restaurant_id, status: @tablesetting.status } }
    assert_redirected_to edit_restaurant_url(@tablesetting.restaurant)
  end

  test "should destroy tablesetting" do
    assert_difference("Tablesetting.count", 0) do
      delete tablesetting_url(@tablesetting)
    end
    assert_redirected_to edit_restaurant_url(@tablesetting.restaurant)
  end
end
