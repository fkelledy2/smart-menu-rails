require "test_helper"


class RestaurantsControllerTest < ActionDispatch::IntegrationTest

  setup do
    sign_in users(:one)
    @restaurant = restaurants(:one)
  end

  test "should get index" do
    get restaurants_url
    assert_response :success
  end

  test "should get new" do
    get new_restaurant_url
    assert_response :success
  end

  test "should create restaurant" do
    assert_difference("Restaurant.count") do
      post restaurants_url, params: { restaurant: { address1: @restaurant.address1, address2: @restaurant.address2, capacity: @restaurant.capacity, city: @restaurant.city, country: @restaurant.country, description: @restaurant.description, image: @restaurant.image, name: @restaurant.name, postcode: @restaurant.postcode, state: @restaurant.state, status: @restaurant.status, user_id: @restaurant.user_id } }
    end
    assert_redirected_to restaurants_url
  end

  test "should show restaurant" do
    get restaurant_url(@restaurant)
    assert_response :success
  end

  test "should get edit" do
    get edit_restaurant_url(@restaurant)
    assert_response :success
  end

  test "should update restaurant" do
    patch restaurant_url(@restaurant), params: { restaurant: { address1: @restaurant.address1, address2: @restaurant.address2, capacity: @restaurant.capacity, city: @restaurant.city, country: @restaurant.country, description: @restaurant.description, image: @restaurant.image, name: @restaurant.name, postcode: @restaurant.postcode, state: @restaurant.state, status: @restaurant.status, user_id: @restaurant.user_id } }
    assert_redirected_to edit_restaurant_url(@restaurant)
  end

  test "should destroy restaurant" do
    assert_difference("Restaurant.count", 0) do
      delete restaurant_url(@restaurant)
    end
    assert_redirected_to restaurants_url
  end
end
