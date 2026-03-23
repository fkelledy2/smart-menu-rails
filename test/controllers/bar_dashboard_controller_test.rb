# frozen_string_literal: true

require 'test_helper'

class BarDashboardControllerTest < ActionDispatch::IntegrationTest
  test 'GET index redirects unauthenticated users' do
    get bar_dashboard_restaurant_path(restaurants(:one))
    assert_redirected_to new_user_session_path
  end

  test 'GET index succeeds for authenticated restaurant owner' do
    sign_in users(:one)
    get bar_dashboard_restaurant_path(restaurants(:one))
    assert_response :success
  end
end
