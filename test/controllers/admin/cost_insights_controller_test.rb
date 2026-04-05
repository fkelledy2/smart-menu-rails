# frozen_string_literal: true

require 'test_helper'

class Admin::CostInsightsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin   = users(:super_admin)
    @plain_admin   = users(:admin)
    @regular_user  = users(:one)
    Flipper.enable(:cost_insights_admin, @super_admin)
  end

  teardown do
    Flipper.disable(:cost_insights_admin)
  end

  # ---------------------------------------------------------------------------
  # Access control — unauthenticated
  # ---------------------------------------------------------------------------

  test 'unauthenticated user is redirected from index' do
    get admin_cost_insights_path
    assert_response :redirect
  end

  # ---------------------------------------------------------------------------
  # Access control — non-super-admin
  # ---------------------------------------------------------------------------

  test 'plain admin is redirected to root' do
    sign_in @plain_admin
    get admin_cost_insights_path
    assert_redirected_to root_path
  end

  test 'regular user is redirected to root' do
    sign_in @regular_user
    get admin_cost_insights_path
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Index — super admin
  # ---------------------------------------------------------------------------

  test 'super admin can access cost insights dashboard' do
    sign_in @super_admin
    get admin_cost_insights_path
    assert_response :ok
  end

  test 'dashboard renders cost cards' do
    sign_in @super_admin
    get admin_cost_insights_path
    assert_select '.card'
  end

  test 'dashboard accepts month parameter' do
    sign_in @super_admin
    get admin_cost_insights_path, params: { month: Date.current.prev_month.strftime('%Y-%m-%d') }
    assert_response :ok
  end

  test 'dashboard accepts currency parameter' do
    sign_in @super_admin
    get admin_cost_insights_path, params: { currency: 'USD' }
    assert_response :ok
  end

  test 'dashboard handles invalid month gracefully' do
    sign_in @super_admin
    get admin_cost_insights_path, params: { month: 'not-a-date' }
    assert_response :ok
  end

  # ---------------------------------------------------------------------------
  # Trigger monthly rollup
  # ---------------------------------------------------------------------------

  test 'super admin can trigger monthly rollup' do
    sign_in @super_admin
    assert_enqueued_with(job: MonthlyCostRollupJob) do
      post trigger_monthly_rollup_admin_cost_insights_path, params: { month: Date.current.strftime('%Y-%m-%d') }
    end
    assert_redirected_to admin_cost_insights_path
  end

  test 'non-super-admin cannot trigger rollup' do
    sign_in @plain_admin
    post trigger_monthly_rollup_admin_cost_insights_path
    assert_redirected_to root_path
  end

  test 'rollup with invalid month redirects with alert' do
    sign_in @super_admin
    post trigger_monthly_rollup_admin_cost_insights_path, params: { month: 'bad-date' }
    assert_redirected_to admin_cost_insights_path
    assert_equal 'Invalid month parameter.', flash[:alert]
  end
end
