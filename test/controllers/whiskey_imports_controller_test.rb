# frozen_string_literal: true

require 'test_helper'

class WhiskeyImportsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
  end

  test 'GET new redirects unauthenticated' do
    get new_whiskey_import_restaurant_path(@restaurant)
    assert_redirected_to new_user_session_path
  end

  test 'GET new succeeds for restaurant owner' do
    sign_in users(:one)
    get new_whiskey_import_restaurant_path(@restaurant)
    assert_response :success
  end
end
