# frozen_string_literal: true

require 'test_helper'

class ProfitMarginsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
  end

  test 'GET index redirects unauthenticated' do
    get restaurant_profit_margins_path(@restaurant)
    assert_redirected_to new_user_session_path
  end

  test 'GET index redirects authenticated user to restaurant edit page' do
    sign_in users(:one)
    get restaurant_profit_margins_path(@restaurant)
    assert_redirected_to edit_restaurant_path(@restaurant, section: 'profitability_margins')
  end

  test 'GET report redirects authenticated user to restaurant edit page' do
    sign_in users(:one)
    get restaurant_profit_margins_report_path(@restaurant)
    assert_redirected_to edit_restaurant_path(@restaurant, section: 'profitability_margins')
  end
end
