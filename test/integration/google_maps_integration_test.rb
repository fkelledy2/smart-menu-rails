require 'test_helper'

class GoogleMapsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
  end

  test 'restaurants index includes google maps loader' do
    get restaurants_url
    assert_response :success
    assert_includes @response.body, 'window.initGoogleMaps'
    assert_includes @response.body, 'maps.googleapis.com/maps/api/js'
    assert_includes @response.body, 'libraries=places'
  end

  test 'new restaurant modal frame response includes address input' do
    get new_restaurant_url, headers: { 'Turbo-Frame' => 'new_restaurant_modal' }
    assert_response :success
    assert_includes @response.body, 'turbo-frame id="new_restaurant_modal"'
    assert_includes @response.body, 'id="restaurant_address1"'
  end

  test 'restaurant edit details renders map container when lat/lng present' do
    restaurant = restaurants(:one)
    restaurant.update!(latitude: 51.5074, longitude: -0.1278)

    get edit_restaurant_url(restaurant, section: 'details')
    assert_response :success
    assert_includes @response.body, 'id="restaurant-map"'
    assert_includes @response.body, 'data-latitude="51.5074"'
    assert_includes @response.body, 'data-longitude="-0.1278"'
  end
end
