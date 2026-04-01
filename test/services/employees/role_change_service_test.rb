require 'test_helper'

module Employees
  class RoleChangeServiceTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    def setup
      @restaurant      = restaurants(:one)
      @admin_employee  = employees(:admin_employee)     # role: admin
      @manager_employee = employees(:one)               # role: manager
      @staff_employee = employees(:staff_member) # role: staff
    end

    # === HAPPY PATH ===

    test 'admin can promote staff to manager' do
      result = RoleChangeService.call(
        acting_employee: @admin_employee,
        target_employee: @staff_employee,
        to_role: 'manager',
        reason: 'Consistently reliable during peak hours',
      )

      assert result.success?, result.error
      assert_equal 'manager', @staff_employee.reload.role
      assert_not_nil result.audit
      assert_equal 'staff',   result.audit.from_role
      assert_equal 'manager', result.audit.to_role
    end

    test 'admin can promote staff to admin' do
      result = RoleChangeService.call(
        acting_employee: @admin_employee,
        target_employee: @staff_employee,
        to_role: 'admin',
        reason: 'Taking over restaurant management responsibilities fully',
      )

      assert result.success?, result.error
      assert_equal 'admin', @staff_employee.reload.role
    end

    test 'admin can promote manager to admin' do
      result = RoleChangeService.call(
        acting_employee: @admin_employee,
        target_employee: @manager_employee,
        to_role: 'admin',
        reason: 'Long-serving manager now taking on ownership duties',
      )

      assert result.success?, result.error
      assert_equal 'admin', @manager_employee.reload.role
    end

    test 'admin can demote admin to manager' do
      result = RoleChangeService.call(
        acting_employee: @admin_employee,
        target_employee: @manager_employee,
        to_role: 'staff',
        reason: 'Stepping back from management by personal request from employee',
      )

      assert result.success?, result.error
      assert_equal 'staff', @manager_employee.reload.role
    end

    test 'manager can promote staff to manager' do
      result = RoleChangeService.call(
        acting_employee: @manager_employee,
        target_employee: @staff_employee,
        to_role: 'manager',
        reason: 'Staff member ready for additional responsibilities this season',
      )

      assert result.success?, result.error
      assert_equal 'manager', @staff_employee.reload.role
    end

    test 'creates an EmployeeRoleAudit record on success' do
      assert_difference 'EmployeeRoleAudit.count', 1 do
        RoleChangeService.call(
          acting_employee: @admin_employee,
          target_employee: @staff_employee,
          to_role: 'manager',
          reason: 'Well-deserved promotion after a strong quarter',
        )
      end
    end

    test 'audit record has correct attributes' do
      result = RoleChangeService.call(
        acting_employee: @admin_employee,
        target_employee: @staff_employee,
        to_role: 'manager',
        reason: 'Audit attribute verification test reason here',
      )

      audit = result.audit
      assert_equal @staff_employee.id,  audit.employee_id
      assert_equal @restaurant.id,      audit.restaurant_id
      assert_equal @admin_employee.id,  audit.changed_by_id
      assert_equal 'staff',             audit.from_role
      assert_equal 'manager',           audit.to_role
      assert_equal 'Audit attribute verification test reason here', audit.reason
    end

    test 'enqueues EmployeeRoleChangedJob after successful change' do
      assert_enqueued_with(job: EmployeeRoleChangedJob) do
        RoleChangeService.call(
          acting_employee: @admin_employee,
          target_employee: @staff_employee,
          to_role: 'manager',
          reason: 'Background job enqueue verification test reason',
        )
      end
    end

    # === FAILURE CASES ===

    test 'fails when acting employee is nil' do
      result = RoleChangeService.call(
        acting_employee: nil,
        target_employee: @staff_employee,
        to_role: 'manager',
        reason: 'Should not matter because acting_employee is nil',
      )

      assert_not result.success?
      assert_equal 'Acting employee is required', result.error
    end

    test 'fails when target employee is nil' do
      result = RoleChangeService.call(
        acting_employee: @admin_employee,
        target_employee: nil,
        to_role: 'manager',
        reason: 'Should not matter because target_employee is nil',
      )

      assert_not result.success?
      assert_equal 'Target employee is required', result.error
    end

    test 'fails when acting employee tries to change their own role' do
      result = RoleChangeService.call(
        acting_employee: @admin_employee,
        target_employee: @admin_employee,
        to_role: 'manager',
        reason: 'Should not be able to change own role via service',
      )

      assert_not result.success?
      assert_equal 'Cannot change your own role', result.error
    end

    test 'fails with invalid role name' do
      result = RoleChangeService.call(
        acting_employee: @admin_employee,
        target_employee: @staff_employee,
        to_role: 'superuser',
        reason: 'Trying an invalid role name for testing',
      )

      assert_not result.success?
      assert_equal 'Invalid role', result.error
    end

    test 'fails when target already has the requested role' do
      result = RoleChangeService.call(
        acting_employee: @admin_employee,
        target_employee: @staff_employee,
        to_role: 'staff',
        reason: 'Attempting a no-op role change for testing purposes',
      )

      assert_not result.success?
      assert_equal 'No change: employee already has this role', result.error
    end

    test 'fails when reason is too short' do
      result = RoleChangeService.call(
        acting_employee: @admin_employee,
        target_employee: @staff_employee,
        to_role: 'manager',
        reason: 'Short',
      )

      assert_not result.success?
      assert_equal 'Reason must be at least 10 characters', result.error
    end

    test 'manager cannot promote staff to admin' do
      result = RoleChangeService.call(
        acting_employee: @manager_employee,
        target_employee: @staff_employee,
        to_role: 'admin',
        reason: 'Manager should not be able to promote to admin level',
      )

      assert_not result.success?
      assert_equal 'Insufficient permissions to make this role change', result.error
    end

    test 'manager cannot demote another manager' do
      result = RoleChangeService.call(
        acting_employee: @manager_employee,
        target_employee: @admin_employee,
        to_role: 'staff',
        reason: 'Manager should not be able to demote admin or manager',
      )

      assert_not result.success?
      assert_equal 'Insufficient permissions to make this role change', result.error
    end

    test 'staff cannot change any role' do
      result = RoleChangeService.call(
        acting_employee: @staff_employee,
        target_employee: @manager_employee,
        to_role: 'staff',
        reason: 'Staff member should never be able to change roles',
      )

      assert_not result.success?
      assert_equal 'Insufficient permissions to make this role change', result.error
    end

    test 'fails when employees are from different restaurants' do
      other_restaurant = restaurants(:two)
      other_user = users(:two)
      other_employee = Employee.create!(
        name: 'Other Restaurant Employee',
        eid: 'OTH001',
        role: :staff,
        status: :active,
        restaurant: other_restaurant,
        user: other_user,
      )

      result = RoleChangeService.call(
        acting_employee: @admin_employee,
        target_employee: other_employee,
        to_role: 'manager',
        reason: 'Cross-restaurant role change should never be permitted',
      )

      assert_not result.success?
      assert_equal 'Employees must belong to the same restaurant', result.error
    ensure
      other_employee&.destroy
    end

    test 'does not change role on failure' do
      original_role = @staff_employee.role

      RoleChangeService.call(
        acting_employee: @manager_employee,
        target_employee: @staff_employee,
        to_role: 'admin', # not permitted for manager
        reason: 'Attempting disallowed admin promotion by manager',
      )

      assert_equal original_role, @staff_employee.reload.role
    end
  end
end
