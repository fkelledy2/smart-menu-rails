require "test_helper"

class RestaurantavailabilitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restaurantavailability = restaurantavailabilities(:one)
  end

  test "should get index" do
    get restaurantavailabilities_url
    assert_response :success
  end

  test "should get new" do
    get new_restaurantavailability_url
    assert_response :success
  end

  test "should create restaurantavailability" do
    assert_difference("Restaurantavailability.count") do
      post restaurantavailabilities_url, params: { restaurantavailability: { dayofweek: @restaurantavailability.dayofweek, endhour: @restaurantavailability.endhour, endmin: @restaurantavailability.endmin, restaurant_id: @restaurantavailability.restaurant_id, starthour: @restaurantavailability.starthour, startmin: @restaurantavailability.startmin } }
    end

    assert_redirected_to restaurantavailability_url(Restaurantavailability.last)
  end

  test "should show restaurantavailability" do
    get restaurantavailability_url(@restaurantavailability)
    assert_response :success
  end

  test "should get edit" do
    get edit_restaurantavailability_url(@restaurantavailability)
    assert_response :success
  end

  test "should update restaurantavailability" do
    patch restaurantavailability_url(@restaurantavailability), params: { restaurantavailability: { dayofweek: @restaurantavailability.dayofweek, endhour: @restaurantavailability.endhour, endmin: @restaurantavailability.endmin, restaurant_id: @restaurantavailability.restaurant_id, starthour: @restaurantavailability.starthour, startmin: @restaurantavailability.startmin } }
    assert_redirected_to restaurantavailability_url(@restaurantavailability)
  end

  test "should destroy restaurantavailability" do
    assert_difference("Restaurantavailability.count", -1) do
      delete restaurantavailability_url(@restaurantavailability)
    end

    assert_redirected_to restaurantavailabilities_url
  end
end
