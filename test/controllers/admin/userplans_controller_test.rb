# frozen_string_literal: true

require 'test_helper'

class Admin::UserplansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin  = users(:super_admin)
    @plain_admin  = users(:admin)
    @regular_user = users(:one)
    @userplan     = userplans(:one)
    @plan         = plans(:pro)
  end

  # ---------------------------------------------------------------------------
  # Access control
  # ---------------------------------------------------------------------------

  test 'unauthenticated user cannot access pricing_override' do
    post pricing_override_admin_userplan_path(@userplan),
         params: { plan_id: @plan.id, reason: 'test' }
    assert_response :redirect
  end

  test 'plain admin cannot access pricing_override' do
    sign_in @plain_admin
    post pricing_override_admin_userplan_path(@userplan),
         params: { plan_id: @plan.id, reason: 'test' }
    assert_redirected_to root_path
  end

  test 'regular user cannot access pricing_override' do
    sign_in @regular_user
    post pricing_override_admin_userplan_path(@userplan),
         params: { plan_id: @plan.id, reason: 'test' }
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Happy path
  # ---------------------------------------------------------------------------

  test 'super admin can apply pricing override with valid reason' do
    sign_in @super_admin

    assert_changes -> { @userplan.reload.pricing_override_keep_original_cohort }, to: true do
      post pricing_override_admin_userplan_path(@userplan),
           params: { plan_id: @plan.id, reason: 'Grandfathering legacy customer' }
    end

    assert_response :redirect
    assert @userplan.reload.pricing_override_keep_original_cohort
    assert_equal @super_admin.id, @userplan.reload.pricing_override_by_user_id
  end

  # ---------------------------------------------------------------------------
  # Validation errors
  # ---------------------------------------------------------------------------

  test 'override without reason redirects with alert' do
    sign_in @super_admin

    post pricing_override_admin_userplan_path(@userplan),
         params: { plan_id: @plan.id, reason: '' }

    assert_response :redirect
    assert_not @userplan.reload.pricing_override_keep_original_cohort
  end

  test 'override with invalid plan_id redirects with alert' do
    sign_in @super_admin

    post pricing_override_admin_userplan_path(@userplan),
         params: { plan_id: 0, reason: 'test' }

    assert_response :redirect
  end
end
