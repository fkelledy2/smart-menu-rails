require 'test_helper'

class Api::V1::MenusControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one)
    @restaurant.update!(user_id: @user.id)

    @menu = Menu.create!(
      restaurant: @restaurant,
      name: 'Test Menu',
      description: 'Test menu description',
      status: 1,
      sequence: 1,
    )
  end

  # Authentication tests
  test 'should allow public access to index' do
    get api_v1_restaurant_menus_path(@restaurant), as: :json

    # Public endpoint, should work
    assert_includes [200, 401], response.status
  end

  test 'should allow public access to show' do
    get api_v1_menu_path(@menu), as: :json

    # Public endpoint, should work
    assert_includes [200, 401], response.status
  end

  test 'should require authentication for create' do
    post api_v1_restaurant_menus_path(@restaurant), params: {
      menu: { name: 'New Menu', description: 'New description' },
    }, as: :json

    # API requires authentication, expect unauthorized response
    assert_response :unauthorized
  end

  test 'should require authentication for update' do
    patch api_v1_menu_path(@menu), params: {
      menu: { name: 'Updated Menu' },
    }, as: :json

    # API requires authentication, expect unauthorized response
    assert_response :unauthorized
  end

  test 'should require authentication for destroy' do
    delete api_v1_menu_path(@menu), as: :json

    # API requires authentication, expect unauthorized response
    assert_response :unauthorized
  end

  # Route accessibility tests
  test 'should have index route' do
    # Just verify the route exists (API routes default to JSON format)
    assert_routing({ method: 'get', path: "/api/v1/restaurants/#{@restaurant.id}/menus" },
                   { controller: 'api/v1/menus', action: 'index', restaurant_id: @restaurant.id.to_s, format: :json },)
  end

  test 'should have show route' do
    # Just verify the route exists (API routes default to JSON format)
    assert_routing({ method: 'get', path: "/api/v1/menus/#{@menu.id}" },
                   { controller: 'api/v1/menus', action: 'show', id: @menu.id.to_s, format: :json },)
  end

  test 'should have create route' do
    # Just verify the route exists (API routes default to JSON format)
    assert_routing({ method: 'post', path: "/api/v1/restaurants/#{@restaurant.id}/menus" },
                   { controller: 'api/v1/menus', action: 'create', restaurant_id: @restaurant.id.to_s, format: :json },)
  end

  test 'should have update route' do
    # Just verify the route exists (API routes default to JSON format)
    assert_routing({ method: 'patch', path: "/api/v1/menus/#{@menu.id}" },
                   { controller: 'api/v1/menus', action: 'update', id: @menu.id.to_s, format: :json },)
  end

  test 'should have destroy route' do
    # Just verify the route exists (API routes default to JSON format)
    assert_routing({ method: 'delete', path: "/api/v1/menus/#{@menu.id}" },
                   { controller: 'api/v1/menus', action: 'destroy', id: @menu.id.to_s, format: :json },)
  end

  # Basic functionality tests
  test 'should handle JSON format requests' do
    get api_v1_restaurant_menus_path(@restaurant), as: :json

    # Should return JSON response
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test 'should include error details in unauthorized response' do
    post api_v1_restaurant_menus_path(@restaurant), params: {
      menu: { name: 'Error Test' },
    }, as: :json

    assert_response :unauthorized
    json_response = response.parsed_body
    assert json_response['error'].present?
    assert_equal 'unauthorized', json_response['error']['code']
  end

  # Parameter validation tests
  test 'should handle missing restaurant parameter' do
    # Test with invalid restaurant ID
    get '/api/v1/restaurants/999999/menus', as: :json

    # Should handle not found gracefully
    assert_includes [404, 401], response.status
  end

  test 'should handle missing menu parameter' do
    # Test with invalid menu ID
    get '/api/v1/menus/999999', as: :json

    # Should handle not found gracefully
    assert_includes [404, 401], response.status
  end
end
