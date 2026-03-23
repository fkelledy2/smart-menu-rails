# frozen_string_literal: true

require 'test_helper'

class RestaurantsControllerTest < ActionDispatch::IntegrationTest
  test 'GET index redirects unauthenticated' do
    get restaurants_path
    assert_redirected_to new_user_session_path
  end

  test 'GET index succeeds for authenticated user' do
    sign_in users(:one)
    get restaurants_path
    assert_response :success
  end

  test 'GET new redirects unauthenticated' do
    get new_restaurant_path
    assert_redirected_to new_user_session_path
  end

  test 'GET new succeeds for authenticated user' do
    sign_in users(:one)
    get new_restaurant_path
    assert_response :success
  end

  test 'GET edit succeeds for restaurant owner' do
    sign_in users(:one)
    get edit_restaurant_path(restaurants(:one))
    assert_response :success
  end
end
