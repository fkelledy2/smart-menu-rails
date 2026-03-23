# frozen_string_literal: true

require 'test_helper'

class MenuOptimizationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
  end

  test 'GET index redirects unauthenticated' do
    get restaurant_menu_optimizations_path(@restaurant)
    assert_redirected_to new_user_session_path
  end

  test 'GET index redirects to profitability section' do
    sign_in users(:one)
    get restaurant_menu_optimizations_path(@restaurant)
    assert_redirected_to edit_restaurant_path(@restaurant, section: 'profitability')
  end

  test 'GET menu_engineering redirects to profitability section' do
    sign_in users(:one)
    get restaurant_menu_optimizations_menu_engineering_path(@restaurant)
    assert_redirected_to edit_restaurant_path(@restaurant, section: 'profitability_optimization')
  end
end
