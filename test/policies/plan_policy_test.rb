require 'test_helper'

class PlanPolicyTest < ActiveSupport::TestCase
  def setup
    @admin_user = users(:admin)
    @regular_user = users(:one)
    @plan = plans(:one)
  end

  test 'index is public - allowed for authenticated user' do
    policy = PlanPolicy.new(@regular_user, @plan)
    assert policy.index?
  end

  test 'index is public - allowed for anonymous user' do
    policy = PlanPolicy.new(nil, @plan)
    assert policy.index?
  end

  test 'show is public - allowed for authenticated user' do
    policy = PlanPolicy.new(@regular_user, @plan)
    assert policy.show?
  end

  test 'show is public - allowed for anonymous user' do
    policy = PlanPolicy.new(nil, @plan)
    assert policy.show?
  end

  test 'create is allowed for admin user' do
    policy = PlanPolicy.new(@admin_user, @plan)
    assert policy.create?
  end

  test 'create is denied for regular user' do
    policy = PlanPolicy.new(@regular_user, @plan)
    assert_not policy.create?
  end

  test 'create is denied for anonymous user' do
    policy = PlanPolicy.new(nil, @plan)
    assert_not policy.create?
  end

  test 'update is allowed for admin user' do
    policy = PlanPolicy.new(@admin_user, @plan)
    assert policy.update?
  end

  test 'update is denied for regular user' do
    policy = PlanPolicy.new(@regular_user, @plan)
    assert_not policy.update?
  end

  test 'destroy is allowed for admin user' do
    policy = PlanPolicy.new(@admin_user, @plan)
    assert policy.destroy?
  end

  test 'destroy is denied for regular user' do
    policy = PlanPolicy.new(@regular_user, @plan)
    assert_not policy.destroy?
  end

  test 'scope resolves all plans' do
    scope = PlanPolicy::Scope.new(@regular_user, Plan.all)
    result = scope.resolve
    assert_equal Plan.count, result.count
  end

  test 'inherits from ApplicationPolicy' do
    assert PlanPolicy < ApplicationPolicy
  end
end
