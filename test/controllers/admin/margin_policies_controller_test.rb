# frozen_string_literal: true

require 'test_helper'

class Admin::MarginPoliciesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin   = users(:super_admin)
    @plain_admin   = users(:admin)
    @policy        = profit_margin_policies(:default)
  end

  # ---------------------------------------------------------------------------
  # Access control
  # ---------------------------------------------------------------------------

  test 'unauthenticated user cannot access index' do
    get admin_margin_policies_path
    assert_response :redirect
  end

  test 'plain admin cannot access margin policies' do
    sign_in @plain_admin
    get admin_margin_policies_path
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Index
  # ---------------------------------------------------------------------------

  test 'super admin can list margin policies' do
    sign_in @super_admin
    get admin_margin_policies_path
    assert_response :ok
  end

  # ---------------------------------------------------------------------------
  # New / Create
  # ---------------------------------------------------------------------------

  test 'super admin can load new form' do
    sign_in @super_admin
    get new_admin_margin_policy_path
    assert_response :ok
  end

  test 'super admin can create a margin policy' do
    sign_in @super_admin
    assert_difference('ProfitMarginPolicy.count', 1) do
      post admin_margin_policies_path, params: {
        profit_margin_policy: {
          key: "test_#{SecureRandom.hex(4)}",
          target_gross_margin_pct: 65,
          floor_gross_margin_pct: 45,
          status: 'inactive',
        },
      }
    end
    assert_redirected_to admin_margin_policies_path
  end

  test 'invalid create renders new form' do
    sign_in @super_admin
    assert_no_difference('ProfitMarginPolicy.count') do
      post admin_margin_policies_path, params: {
        profit_margin_policy: {
          key: '',
          target_gross_margin_pct: 0,
          floor_gross_margin_pct: 0,
        },
      }
    end
    assert_response :unprocessable_entity
  end

  # ---------------------------------------------------------------------------
  # Edit / Update
  # ---------------------------------------------------------------------------

  test 'super admin can load edit form' do
    sign_in @super_admin
    get edit_admin_margin_policy_path(@policy)
    assert_response :ok
  end

  test 'super admin can update a margin policy' do
    sign_in @super_admin
    patch admin_margin_policy_path(@policy), params: {
      profit_margin_policy: {
        key: @policy.key,
        target_gross_margin_pct: 70,
        floor_gross_margin_pct: 45,
      },
    }
    assert_redirected_to admin_margin_policies_path
    assert_equal 70, @policy.reload.target_gross_margin_pct
  end

  # ---------------------------------------------------------------------------
  # Activate / Deactivate
  # ---------------------------------------------------------------------------

  test 'super admin can activate a policy' do
    sign_in @super_admin
    @policy.update_column(:status, 0) # inactive
    patch activate_admin_margin_policy_path(@policy)
    assert_redirected_to admin_margin_policies_path
    assert @policy.reload.active?
  end

  test 'super admin can deactivate a policy' do
    sign_in @super_admin
    @policy.update_column(:status, 1) # active
    patch deactivate_admin_margin_policy_path(@policy)
    assert_redirected_to admin_margin_policies_path
    assert @policy.reload.inactive?
  end

  # ---------------------------------------------------------------------------
  # Destroy
  # ---------------------------------------------------------------------------

  test 'super admin can delete a margin policy' do
    sign_in @super_admin
    p = ProfitMarginPolicy.create!(
      key: "deletable_#{SecureRandom.hex(4)}",
      target_gross_margin_pct: 60,
      floor_gross_margin_pct: 40,
      status: :inactive,
    )
    assert_difference('ProfitMarginPolicy.count', -1) do
      delete admin_margin_policy_path(p)
    end
    assert_redirected_to admin_margin_policies_path
  end

  test 'missing record redirects with alert' do
    sign_in @super_admin
    get edit_admin_margin_policy_path(id: 999_999)
    assert_redirected_to admin_margin_policies_path
  end
end
