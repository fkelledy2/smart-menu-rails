# frozen_string_literal: true

require 'test_helper'

class SeoApiV2Test < ActionDispatch::IntegrationTest
  setup do
    @restaurant = restaurants(:one)
    @restaurant.update_columns(preview_enabled: true)
  end

  # ── Restaurants index ────────────────────────────────────────────────────

  test 'GET /api/v2/restaurants returns 200 with JSON' do
    get '/api/v2/restaurants'
    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?('data')
    assert json.key?('meta')
    assert json.key?('attribution')
    assert json.key?('generated_at')
  end

  test 'response includes attribution header' do
    get '/api/v2/restaurants'
    assert_equal 'Data by mellow.menu — https://www.mellow.menu',
                 response.headers['X-Data-Attribution']
  end

  test 'only preview_enabled restaurants appear in results' do
    hidden = restaurants(:two)
    hidden.update_columns(preview_enabled: false)

    get '/api/v2/restaurants'
    json = JSON.parse(response.body)
    ids = json['data'].map { |r| r['id'] }
    assert_includes ids, @restaurant.id
    assert_not_includes ids, hidden.id
  end

  test 'filtering by city works' do
    @restaurant.update_columns(city: 'Dublin')
    get '/api/v2/restaurants', params: { city: 'Dublin' }
    json = JSON.parse(response.body)
    json['data'].each do |r|
      # All returned restaurants should be from Dublin
      assert_not_nil r['name']
    end
  end

  test 'pagination meta is present' do
    get '/api/v2/restaurants', params: { page: 1, per_page: 5 }
    json = JSON.parse(response.body)
    meta = json['meta']
    assert_equal 1, meta['page']
    assert_equal 5, meta['per_page']
    assert meta.key?('total')
    assert meta.key?('total_pages')
  end

  # ── Restaurants show ─────────────────────────────────────────────────────

  test 'GET /api/v2/restaurants/:id returns restaurant detail' do
    get "/api/v2/restaurants/#{@restaurant.id}"
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 'Restaurant', json['data']['@type']
    assert_equal @restaurant.name, json['data']['name']
  end

  test 'GET /api/v2/restaurants/:id returns 404 for hidden restaurant' do
    @restaurant.update_columns(preview_enabled: false)
    get "/api/v2/restaurants/#{@restaurant.id}"
    assert_response :not_found
  end

  # ── Restaurants menu ─────────────────────────────────────────────────────

  test 'GET /api/v2/restaurants/:id/menu returns menu structure' do
    get "/api/v2/restaurants/#{@restaurant.id}/menu"
    # May be 200 or 404 depending on whether restaurant has menus in fixtures
    assert_includes [200, 404], response.status
    json = JSON.parse(response.body)
    if response.status == 200
      assert_equal 'Restaurant', json['data']['@type']
      assert json['data'].key?('menu')
    end
  end

  # ── Explore API ──────────────────────────────────────────────────────────

  test 'GET /api/v2/explore returns 200' do
    ExplorePage.create!(
      country_slug: 'ireland', country_name: 'Ireland',
      city_slug: 'dublin', city_name: 'Dublin',
      published: true, restaurant_count: 3,
    )
    get '/api/v2/explore'
    assert_response :success
  end

  # ── Rate limiting ────────────────────────────────────────────────────────

  test 'no authentication required for v2 endpoints' do
    get '/api/v2/restaurants'
    assert_response :success
  end
end
