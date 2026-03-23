# frozen_string_literal: true

require 'test_helper'

class RestaurantAnalyticsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
  end

  test 'GET kpis redirects unauthenticated' do
    get analytics_kpis_restaurant_path(@restaurant), as: :json
    assert_response :unauthorized
  end

  test 'GET kpis returns JSON for restaurant owner' do
    sign_in users(:one)
    get analytics_kpis_restaurant_path(@restaurant), as: :json
    assert_response :success
  end

  test 'GET timeseries redirects unauthenticated' do
    get analytics_timeseries_restaurant_path(@restaurant), as: :json
    assert_response :unauthorized
  end

  test 'GET timeseries returns JSON for restaurant owner' do
    sign_in users(:one)
    get analytics_timeseries_restaurant_path(@restaurant), as: :json
    assert_response :success
  end
end
