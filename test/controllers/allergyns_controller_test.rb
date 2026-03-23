# frozen_string_literal: true

require 'test_helper'

class AllergynsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
  end

  test 'GET index returns success for restaurant owner' do
    sign_in users(:one)
    get restaurant_allergyns_path(@restaurant)
    assert_response :success
  end

  test 'GET new redirects unauthenticated' do
    get new_restaurant_allergyn_path(@restaurant)
    assert_redirected_to new_user_session_path
  end

  test 'GET new succeeds for authenticated user' do
    sign_in users(:one)
    get new_restaurant_allergyn_path(@restaurant)
    assert_response :success
  end

  test 'GET show succeeds for restaurant owner' do
    sign_in users(:one)
    get restaurant_allergyn_path(@restaurant, allergyns(:one))
    assert_response :success
  end
end
