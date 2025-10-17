require 'test_helper'

class RestaurantavailabilitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @restaurantavailability = restaurantavailabilities(:one)
    @restaurant = restaurants(:one)
  end

  test 'should get index' do
    get restaurant_restaurantavailabilities_url(@restaurant)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_restaurantavailability_url(@restaurant)
    assert_response :success
  end

  #   test "should create restaurantavailability" do

  test 'should show restaurantavailability' do
    get restaurant_restaurantavailability_url(@restaurant, @restaurantavailability)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_restaurantavailability_url(@restaurant, @restaurantavailability)
    assert_response :success
  end

  test 'should update restaurantavailability' do
    patch restaurant_restaurantavailability_url(@restaurant, @restaurantavailability), params: {
      restaurantavailability: {
        dayofweek: :tuesday,
        starttime: '09:00',
        endtime: '22:00'
      }
    }
    assert_response :redirect
  end

  test 'should destroy restaurantavailability' do
    delete restaurant_restaurantavailability_url(@restaurant, @restaurantavailability)
    assert_response :redirect
  end
end
