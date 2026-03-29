# frozen_string_literal: true

require 'test_helper'

class Api::V1::Partner::WorkforceControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user       = users(:super_admin)
    @restaurant = restaurants(:one)

    Flipper.enable(:jwt_api_access)

    result = Jwt::TokenGenerator.call(
      admin_user: @user,
      restaurant: @restaurant,
      name: 'Workforce Test Token',
      scopes: ['workforce:read'],
      expires_in: 30.days,
    )
    @raw_jwt = result.raw_jwt

    # Token with wrong scope
    result_bad = Jwt::TokenGenerator.call(
      admin_user: @user,
      restaurant: @restaurant,
      name: 'Wrong Scope Token',
      scopes: ['menu:read'],
      expires_in: 30.days,
    )
    @raw_jwt_bad_scope = result_bad.raw_jwt
  end

  teardown do
    Flipper.disable(:jwt_api_access)
  end

  test 'GET workforce returns 200 with valid JWT and workforce:read scope' do
    get api_v1_restaurant_partner_workforce_path(@restaurant),
        headers: { 'Authorization' => "Bearer #{@raw_jwt}" }

    assert_response :ok
    body = response.parsed_body
    assert_equal @restaurant.id, body['restaurant_id']
    assert body.key?('order_velocity')
    assert body.key?('table_occupancy')
    assert body.key?('top_items')
  end

  test 'GET workforce returns 401 without authentication' do
    get api_v1_restaurant_partner_workforce_path(@restaurant)
    assert_response :unauthorized
  end

  test 'GET workforce returns 403 with wrong scope' do
    get api_v1_restaurant_partner_workforce_path(@restaurant),
        headers: { 'Authorization' => "Bearer #{@raw_jwt_bad_scope}" }

    assert_response :forbidden
    body = response.parsed_body
    assert_equal 'forbidden', body['error']['code']
    assert_match 'workforce:read', body['error']['message']
  end

  test 'GET workforce returns 404 for non-existent restaurant' do
    get api_v1_restaurant_partner_workforce_path(restaurant_id: 999_999),
        headers: { 'Authorization' => "Bearer #{@raw_jwt}" }

    assert_response :not_found
  end

  test 'GET workforce accepts window_minutes parameter' do
    get api_v1_restaurant_partner_workforce_path(@restaurant),
        params: { window_minutes: 30 },
        headers: { 'Authorization' => "Bearer #{@raw_jwt}" }

    assert_response :ok
    body = response.parsed_body
    assert_equal 30, body['window_minutes']
  end
end
