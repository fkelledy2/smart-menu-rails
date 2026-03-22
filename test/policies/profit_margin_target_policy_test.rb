require 'test_helper'

# ProfitMarginTargetPolicy: index? always true. create? checks user.present? (always true).
# update?/destroy? check super_admin? OR restaurant_id in user's restaurants.
class ProfitMarginTargetPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @super_admin = users(:super_admin)

    @target = ProfitMarginTarget.create!(
      restaurant: restaurants(:one),
      target_margin_percentage: 60.0,
      effective_from: Date.current,
    )
    @other_target = ProfitMarginTarget.create!(
      restaurant: restaurants(:two),
      target_margin_percentage: 55.0,
      effective_from: Date.current,
    )
  end

  test 'index is allowed publicly' do
    policy = ProfitMarginTargetPolicy.new(@owner, @target)
    assert policy.index?
  end

  test 'index is allowed for nil user (always true)' do
    policy = ProfitMarginTargetPolicy.new(nil, @target)
    assert policy.index?
  end

  test 'create is allowed for authenticated user' do
    policy = ProfitMarginTargetPolicy.new(@owner, @target)
    assert policy.create?
  end

  test 'create is allowed for guest (user.present? always true)' do
    policy = ProfitMarginTargetPolicy.new(nil, @target)
    assert policy.create?
  end

  test 'update is allowed for owner' do
    policy = ProfitMarginTargetPolicy.new(@owner, @target)
    assert policy.update?
  end

  test 'update is denied for non-owner' do
    policy = ProfitMarginTargetPolicy.new(@other_user, @target)
    assert_not policy.update?
  end

  test 'update is allowed for super admin' do
    policy = ProfitMarginTargetPolicy.new(@super_admin, @target)
    assert policy.update?
  end

  test 'destroy delegates to update' do
    policy_owner = ProfitMarginTargetPolicy.new(@owner, @target)
    policy_other = ProfitMarginTargetPolicy.new(@other_user, @target)
    assert policy_owner.destroy?
    assert_not policy_other.destroy?
  end

  test 'inherits from ApplicationPolicy' do
    assert ProfitMarginTargetPolicy < ApplicationPolicy
  end

  test 'scope returns all for super admin' do
    scope = ProfitMarginTargetPolicy::Scope.new(@super_admin, ProfitMarginTarget.all)
    assert scope.resolve.count >= 2
  end

  test 'scope returns only owned for regular user' do
    scope = ProfitMarginTargetPolicy::Scope.new(@owner, ProfitMarginTarget.all)
    result = scope.resolve
    restaurant_ids = @owner.restaurants.pluck(:id)
    result.each do |t|
      assert_includes restaurant_ids, t.restaurant_id
    end
  end
end
