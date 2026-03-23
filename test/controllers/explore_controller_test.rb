# frozen_string_literal: true

require 'test_helper'

class ExploreControllerTest < ActionDispatch::IntegrationTest
  test 'GET index succeeds anonymously' do
    get explore_index_path
    assert_response :success
  end

  test 'GET country returns 404 for unknown country' do
    get explore_country_path(country: 'no-such-country-xyz')
    assert_response :not_found
  end

  test 'GET city returns 404 for unknown city' do
    get explore_city_path(country: 'ie', city: 'no-such-city-xyz')
    assert_response :not_found
  end
end
