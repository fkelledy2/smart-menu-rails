# frozen_string_literal: true

require 'test_helper'

class PerformanceAnalyticsControllerTest < ActionDispatch::IntegrationTest
  test 'GET dashboard redirects unauthenticated users' do
    get dashboard_performance_analytics_path
    assert_redirected_to new_user_session_path
  end

  test 'GET dashboard redirects non-admin users to root' do
    sign_in users(:one)
    get dashboard_performance_analytics_path
    assert_redirected_to root_path
  end

  test 'GET api_metrics redirects unauthenticated users' do
    get api_metrics_performance_analytics_path
    assert_redirected_to new_user_session_path
  end
end
