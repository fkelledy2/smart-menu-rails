# frozen_string_literal: true

require 'test_helper'

class Api::V2::RestaurantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restaurant = Restaurant.create!(
      name: 'Test Restaurant',
      description: 'A test restaurant',
      city: 'Dublin',
      country: 'Ireland',
      address1: '123 Test St',
      latitude: 53.35,
      longitude: -6.26,
      currency: 'EUR',
      preview_enabled: true,
      claim_status: 0,
      status: 1,
      establishment_types: ['Italian'],
      user: User.first || User.create!(email: 'api-test@example.com', password: 'password123'),
    )
  end

  teardown do
    @restaurant&.destroy
  end

  test 'GET /api/v2/restaurants returns JSON with published restaurants' do
    get '/api/v2/restaurants', as: :json
    assert_response :success
    json = response.parsed_body

    assert json['data'].is_a?(Array)
    assert json['meta'].present?
    assert json['attribution'].present?
    assert json['generated_at'].present?

    names = json['data'].pluck('name')
    assert_includes names, 'Test Restaurant'
  end

  test 'GET /api/v2/restaurants filters by city' do
    get '/api/v2/restaurants', params: { city: 'Dublin' }, as: :json
    assert_response :success
    json = response.parsed_body
    assert(json['data'].any? { |r| r['name'] == 'Test Restaurant' })
  end

  test 'GET /api/v2/restaurants/:id returns restaurant detail' do
    get "/api/v2/restaurants/#{@restaurant.id}", as: :json
    assert_response :success
    json = response.parsed_body

    assert_equal 'Restaurant', json['data']['@type']
    assert_equal 'Test Restaurant', json['data']['name']
    assert json['data']['address'].present?
    assert json['data']['geo'].present?
  end

  test 'GET /api/v2/restaurants/:id returns 404 for non-existent' do
    get '/api/v2/restaurants/999999', as: :json
    assert_response :not_found
  end

  test 'response includes X-Data-Attribution header' do
    get '/api/v2/restaurants', as: :json
    assert_response :success
    assert_equal 'Data by mellow.menu — https://www.mellow.menu',
                 response.headers['X-Data-Attribution']
  end

  test 'does not expose unpublished restaurants' do
    hidden = Restaurant.create!(
      name: 'Hidden Restaurant',
      city: 'Dublin',
      country: 'Ireland',
      preview_enabled: false,
      status: 1,
      claim_status: 0,
      user: @restaurant.user,
    )

    get '/api/v2/restaurants', as: :json
    json = response.parsed_body
    names = json['data'].pluck('name')
    assert_not_includes names, 'Hidden Restaurant'

    hidden.destroy
  end
end
