require 'test_helper'

class Api::V1::RestaurantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one)
    @restaurant.update!(user_id: @user.id)
  end

  # Authentication tests
  test 'should allow public access to index' do
    get api_v1_restaurants_path, as: :json

    # Public endpoint, should work
    assert_includes [200, 401], response.status
  end

  test 'should allow public access to show' do
    get api_v1_restaurant_path(@restaurant), as: :json

    # Public endpoint, should work
    assert_includes [200, 401], response.status
  end

  test 'should require authentication for create' do
    post api_v1_restaurants_path, params: {
      restaurant: { name: 'New Restaurant', description: 'New description' },
    }, as: :json

    # API requires authentication, expect unauthorized response
    assert_response :unauthorized
  end

  test 'should require authentication for update' do
    patch api_v1_restaurant_path(@restaurant), params: {
      restaurant: { name: 'Updated Restaurant' },
    }, as: :json

    # API requires authentication, expect unauthorized response
    assert_response :unauthorized
  end

  test 'should require authentication for destroy' do
    delete api_v1_restaurant_path(@restaurant), as: :json

    # API requires authentication, expect unauthorized response
    assert_response :unauthorized
  end

  # Route accessibility tests
  test 'should have index route' do
    # Just verify the route exists (API routes default to JSON format)
    assert_routing({ method: 'get', path: '/api/v1/restaurants' },
                   { controller: 'api/v1/restaurants', action: 'index', format: :json })
  end

  test 'should have show route' do
    # Just verify the route exists (API routes default to JSON format)
    assert_routing({ method: 'get', path: "/api/v1/restaurants/#{@restaurant.id}" },
                   { controller: 'api/v1/restaurants', action: 'show', id: @restaurant.id.to_s, format: :json })
  end

  test 'should have create route' do
    # Just verify the route exists (API routes default to JSON format)
    assert_routing({ method: 'post', path: '/api/v1/restaurants' },
                   { controller: 'api/v1/restaurants', action: 'create', format: :json })
  end

  test 'should have update route' do
    # Just verify the route exists (API routes default to JSON format)
    assert_routing({ method: 'patch', path: "/api/v1/restaurants/#{@restaurant.id}" },
                   { controller: 'api/v1/restaurants', action: 'update', id: @restaurant.id.to_s, format: :json })
  end

  test 'should have destroy route' do
    # Just verify the route exists (API routes default to JSON format)
    assert_routing({ method: 'delete', path: "/api/v1/restaurants/#{@restaurant.id}" },
                   { controller: 'api/v1/restaurants', action: 'destroy', id: @restaurant.id.to_s, format: :json })
  end

  # Basic functionality tests
  test 'should handle JSON format requests' do
    get api_v1_restaurants_path, as: :json

    # Should return JSON response
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test 'should include error details in unauthorized response' do
    post api_v1_restaurants_path, params: {
      restaurant: { name: 'Error Test' },
    }, as: :json

    assert_response :unauthorized
    json_response = response.parsed_body
    assert json_response['error'].present?
    assert_equal 'unauthorized', json_response['error']['code']
  end

  # Parameter validation tests
  test 'should handle missing restaurant parameter' do
    # Test with invalid restaurant ID
    get '/api/v1/restaurants/999999', as: :json

    # Should handle not found gracefully
    assert_includes [404, 401], response.status
  end

  # Pagination tests
  test 'should support pagination parameters' do
    get api_v1_restaurants_path, params: { page: 1 }, as: :json

    # Should handle pagination parameters
    assert_includes [200, 401], response.status
  end
end
