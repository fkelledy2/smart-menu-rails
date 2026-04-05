# frozen_string_literal: true

require 'test_helper'

class Admin::VendorCostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin   = users(:super_admin)
    @plain_admin   = users(:admin)
    @regular_user  = users(:one)
    @cost          = external_service_monthly_costs(:openai_march)
  end

  # ---------------------------------------------------------------------------
  # Access control
  # ---------------------------------------------------------------------------

  test 'unauthenticated user is redirected from index' do
    get admin_vendor_costs_path
    assert_response :redirect
  end

  test 'plain admin cannot access vendor costs' do
    sign_in @plain_admin
    get admin_vendor_costs_path
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Index
  # ---------------------------------------------------------------------------

  test 'super admin can list vendor costs' do
    sign_in @super_admin
    get admin_vendor_costs_path
    assert_response :ok
  end

  test 'index filters by month' do
    sign_in @super_admin
    get admin_vendor_costs_path, params: { month: Date.current.strftime('%Y-%m-%d') }
    assert_response :ok
  end

  # ---------------------------------------------------------------------------
  # New / Create
  # ---------------------------------------------------------------------------

  test 'super admin can load new form' do
    sign_in @super_admin
    get new_admin_vendor_cost_path
    assert_response :ok
  end

  test 'super admin can create a vendor cost entry' do
    sign_in @super_admin
    assert_difference('ExternalServiceMonthlyCost.count', 1) do
      post admin_vendor_costs_path, params: {
        external_service_monthly_cost: {
          month: 1.month.ago.beginning_of_month.strftime('%Y-%m-%d'),
          service: 'stripe',
          currency: 'EUR',
          amount_cents: 5000,
          source: 'manual',
          notes: 'Test entry',
        },
      }
    end
    assert_redirected_to admin_vendor_costs_path
  end

  test 'invalid create renders new form' do
    sign_in @super_admin
    assert_no_difference('ExternalServiceMonthlyCost.count') do
      post admin_vendor_costs_path, params: {
        external_service_monthly_cost: {
          month: '',
          service: 'unknown_service',
          currency: 'EUR',
          amount_cents: 0,
          source: 'manual',
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
    get edit_admin_vendor_cost_path(@cost)
    assert_response :ok
  end

  test 'super admin can update a vendor cost entry' do
    sign_in @super_admin
    patch admin_vendor_cost_path(@cost), params: {
      external_service_monthly_cost: { notes: 'Updated notes' },
    }
    assert_redirected_to admin_vendor_costs_path
    assert_equal 'Updated notes', @cost.reload.notes
  end

  # ---------------------------------------------------------------------------
  # Destroy
  # ---------------------------------------------------------------------------

  test 'super admin can delete a vendor cost entry' do
    sign_in @super_admin
    assert_difference('ExternalServiceMonthlyCost.count', -1) do
      delete admin_vendor_cost_path(@cost)
    end
    assert_redirected_to admin_vendor_costs_path
  end

  test 'plain admin cannot delete a vendor cost entry' do
    sign_in @plain_admin
    assert_no_difference('ExternalServiceMonthlyCost.count') do
      delete admin_vendor_cost_path(@cost)
    end
    assert_redirected_to root_path
  end

  test 'missing record redirects with alert' do
    sign_in @super_admin
    get edit_admin_vendor_cost_path(id: 999_999)
    assert_redirected_to admin_vendor_costs_path
  end
end
