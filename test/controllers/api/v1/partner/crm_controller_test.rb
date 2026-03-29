# frozen_string_literal: true

require 'test_helper'

class Api::V1::Partner::CrmControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user       = users(:super_admin)
    @restaurant = restaurants(:one)

    Flipper.enable(:jwt_api_access)

    result = Jwt::TokenGenerator.call(
      admin_user: @user,
      restaurant: @restaurant,
      name: 'CRM Test Token',
      scopes: ['crm:read'],
      expires_in: 30.days,
    )
    @raw_jwt = result.raw_jwt

    result_bad = Jwt::TokenGenerator.call(
      admin_user: @user,
      restaurant: @restaurant,
      name: 'Bad Scope Token',
      scopes: ['orders:read'],
      expires_in: 30.days,
    )
    @raw_jwt_bad_scope = result_bad.raw_jwt
  end

  teardown do
    Flipper.disable(:jwt_api_access)
  end

  test 'GET crm returns 200 with valid JWT and crm:read scope' do
    get api_v1_restaurant_partner_crm_path(@restaurant),
        headers: { 'Authorization' => "Bearer #{@raw_jwt}" }

    assert_response :ok
    body = response.parsed_body
    assert_equal @restaurant.id, body['restaurant_id']
    assert body.key?('order_pacing')
    assert body.key?('repeat_table_count')
    assert body.key?('avg_time_to_bill_seconds')
    assert body.key?('avg_session_duration_seconds')
  end

  test 'GET crm returns 401 without authentication' do
    get api_v1_restaurant_partner_crm_path(@restaurant)
    assert_response :unauthorized
  end

  test 'GET crm returns 403 with wrong scope' do
    get api_v1_restaurant_partner_crm_path(@restaurant),
        headers: { 'Authorization' => "Bearer #{@raw_jwt_bad_scope}" }

    assert_response :forbidden
    body = response.parsed_body
    assert_match 'crm:read', body['error']['message']
  end

  test 'GET crm returns 404 for non-existent restaurant' do
    get api_v1_restaurant_partner_crm_path(restaurant_id: 999_999),
        headers: { 'Authorization' => "Bearer #{@raw_jwt}" }

    assert_response :not_found
  end

  test 'GET crm accepts window_minutes parameter' do
    get api_v1_restaurant_partner_crm_path(@restaurant),
        params: { window_minutes: 15 },
        headers: { 'Authorization' => "Bearer #{@raw_jwt}" }

    assert_response :ok
    body = response.parsed_body
    assert_equal 15, body['window_minutes']
  end
end
