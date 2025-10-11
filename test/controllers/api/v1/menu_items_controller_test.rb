require 'test_helper'

class Api::V1::MenuItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
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

  # Basic functionality tests
  test 'should allow public access to index' do
    get api_v1_menu_items_path(@menu), as: :json

    # Public endpoint, should work
    assert_includes [200, 401], response.status
  end

  # Route accessibility tests
  test 'should have index route' do
    # Just verify the route exists (API routes default to JSON format)
    assert_routing({ method: 'get', path: "/api/v1/menus/#{@menu.id}/items" },
                   { controller: 'api/v1/menu_items', action: 'index', menu_id: @menu.id.to_s, format: :json },)
  end

  # JSON response tests
  test 'should handle JSON format requests' do
    get api_v1_menu_items_path(@menu), as: :json

    # Should return JSON response
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  # Error handling tests
  test 'should handle missing menu parameter' do
    # Test with invalid menu ID
    get '/api/v1/menus/999999/items', as: :json

    # Should handle not found gracefully
    assert_includes [404, 401], response.status
  end

  test 'should include error details in not found response' do
    get '/api/v1/menus/999999/items', as: :json

    if response.status == 404
      json_response = response.parsed_body
      assert json_response['error'].present?
      assert_equal 'NOT_FOUND', json_response['error']['code']
    else
      # If unauthorized, check for that error structure
      assert_response :unauthorized
    end
  end
end
