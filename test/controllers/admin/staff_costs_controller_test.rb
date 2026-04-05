# frozen_string_literal: true

require 'test_helper'

class Admin::StaffCostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin   = users(:super_admin)
    @plain_admin   = users(:admin)
    @snapshot      = staff_cost_snapshots(:march_eur)
  end

  # ---------------------------------------------------------------------------
  # Access control
  # ---------------------------------------------------------------------------

  test 'unauthenticated user is redirected from index' do
    get admin_staff_costs_path
    assert_response :redirect
  end

  test 'plain admin cannot access staff costs' do
    sign_in @plain_admin
    get admin_staff_costs_path
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Index
  # ---------------------------------------------------------------------------

  test 'super admin can list staff cost snapshots' do
    sign_in @super_admin
    get admin_staff_costs_path
    assert_response :ok
  end

  # ---------------------------------------------------------------------------
  # New / Create
  # ---------------------------------------------------------------------------

  test 'super admin can load new form' do
    sign_in @super_admin
    get new_admin_staff_cost_path
    assert_response :ok
  end

  test 'super admin can create a staff cost snapshot' do
    sign_in @super_admin
    assert_difference('StaffCostSnapshot.count', 1) do
      post admin_staff_costs_path, params: {
        staff_cost_snapshot: {
          month: 6.months.ago.beginning_of_month.strftime('%Y-%m-%d'),
          currency: 'EUR',
          support_cost_cents: 20_000,
          staff_cost_cents: 100_000,
          other_ops_cost_cents: 5_000,
          notes: 'Test snapshot',
        },
      }
    end
    assert_redirected_to admin_staff_costs_path
  end

  test 'invalid create renders new form' do
    sign_in @super_admin
    assert_no_difference('StaffCostSnapshot.count') do
      post admin_staff_costs_path, params: {
        staff_cost_snapshot: {
          month: '',
          currency: 'INVALID',
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
    get edit_admin_staff_cost_path(@snapshot)
    assert_response :ok
  end

  test 'super admin can update a snapshot' do
    sign_in @super_admin
    patch admin_staff_cost_path(@snapshot), params: {
      staff_cost_snapshot: { notes: 'Updated' },
    }
    assert_redirected_to admin_staff_costs_path
    assert_equal 'Updated', @snapshot.reload.notes
  end

  # ---------------------------------------------------------------------------
  # Destroy
  # ---------------------------------------------------------------------------

  test 'super admin can delete a snapshot' do
    sign_in @super_admin
    assert_difference('StaffCostSnapshot.count', -1) do
      delete admin_staff_cost_path(@snapshot)
    end
    assert_redirected_to admin_staff_costs_path
  end

  test 'missing record redirects with alert' do
    sign_in @super_admin
    get edit_admin_staff_cost_path(id: 999_999)
    assert_redirected_to admin_staff_costs_path
  end
end
