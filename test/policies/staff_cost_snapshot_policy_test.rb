# frozen_string_literal: true

require 'test_helper'

class StaffCostSnapshotPolicyTest < ActiveSupport::TestCase
  setup do
    @super_admin  = users(:super_admin)
    @plain_admin  = users(:admin)
    @regular_user = users(:one)
    @snapshot     = staff_cost_snapshots(:march_eur)
  end

  test 'super admin can index' do
    assert StaffCostSnapshotPolicy.new(@super_admin, StaffCostSnapshot).index?
  end

  test 'super admin can create' do
    assert StaffCostSnapshotPolicy.new(@super_admin, StaffCostSnapshot).create?
  end

  test 'super admin can update' do
    assert StaffCostSnapshotPolicy.new(@super_admin, @snapshot).update?
  end

  test 'super admin can destroy' do
    assert StaffCostSnapshotPolicy.new(@super_admin, @snapshot).destroy?
  end

  test 'plain admin cannot index' do
    assert_not StaffCostSnapshotPolicy.new(@plain_admin, StaffCostSnapshot).index?
  end

  test 'regular user cannot index' do
    assert_not StaffCostSnapshotPolicy.new(@regular_user, StaffCostSnapshot).index?
  end

  test 'super admin scope returns all snapshots' do
    scope = StaffCostSnapshotPolicy::Scope.new(@super_admin, StaffCostSnapshot).resolve
    assert_includes scope, @snapshot
  end

  test 'non-super-admin scope returns none' do
    scope = StaffCostSnapshotPolicy::Scope.new(@plain_admin, StaffCostSnapshot).resolve
    assert scope.none?
  end
end
