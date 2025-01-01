require "test_helper"

class SizesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @size = sizes(:one)
  end

  test "should get index" do
    get sizes_url
    assert_response :success
  end

  test "should get new" do
    get new_size_url
    assert_response :success
  end

  test "should create size" do
    assert_difference("Size.count") do
      post sizes_url, params: { size: { description: @size.description, name: @size.name, size: @size.size, restaurant_id: @size.restaurant_id } }
    end
    assert_redirected_to edit_restaurant_url(@size.restaurant)
  end

  test "should show size" do
    get size_url(@size)
    assert_response :success
  end

  test "should get edit" do
    get edit_size_url(@size)
    assert_response :success
  end

  test "should update size" do
    patch size_url(@size), params: { size: { description: @size.description, name: @size.name, size: @size.size, restaurant_id: @size.restaurant_id } }
    assert_redirected_to edit_restaurant_url(@size.restaurant)
  end

  test "should destroy size" do
    assert_difference("Size.count", 0) do
      delete size_url(@size)
    end
    assert_redirected_to edit_restaurant_url(@size.restaurant)
  end
end
