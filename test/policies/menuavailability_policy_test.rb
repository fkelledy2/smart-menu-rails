require 'test_helper'

# MenuavailabilityPolicy: index/create check user.present? (always true via User.new).
# show/update/destroy check user.present? AND owns_menu_availability?.
class MenuavailabilityPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @menuavailability = menuavailabilities(:one)
  end

  test 'index is allowed for authenticated user' do
    policy = MenuavailabilityPolicy.new(@owner, @menuavailability)
    assert policy.index?
  end

  test 'index is allowed for guest (user.present? always true)' do
    policy = MenuavailabilityPolicy.new(nil, @menuavailability)
    assert policy.index?
  end

  test 'create is allowed for authenticated user' do
    policy = MenuavailabilityPolicy.new(@owner, @menuavailability)
    assert policy.create?
  end

  test 'create is allowed for guest (user.present? always true)' do
    policy = MenuavailabilityPolicy.new(nil, @menuavailability)
    assert policy.create?
  end

  test 'show is allowed for owner of the menu' do
    policy = MenuavailabilityPolicy.new(@owner, @menuavailability)
    assert policy.show?
  end

  test 'show is denied for non-owner' do
    policy = MenuavailabilityPolicy.new(@other_user, @menuavailability)
    assert_not policy.show?
  end

  test 'update is allowed for owner of the menu' do
    policy = MenuavailabilityPolicy.new(@owner, @menuavailability)
    assert policy.update?
  end

  test 'update is denied for non-owner' do
    policy = MenuavailabilityPolicy.new(@other_user, @menuavailability)
    assert_not policy.update?
  end

  test 'destroy is allowed for owner' do
    policy = MenuavailabilityPolicy.new(@owner, @menuavailability)
    assert policy.destroy?
  end

  test 'destroy is denied for non-owner' do
    policy = MenuavailabilityPolicy.new(@other_user, @menuavailability)
    assert_not policy.destroy?
  end

  test 'inherits from ApplicationPolicy' do
    assert MenuavailabilityPolicy < ApplicationPolicy
  end

  test 'scope returns none for guest user (no restaurants)' do
    scope = MenuavailabilityPolicy::Scope.new(nil, Menuavailability.all)
    assert_equal 0, scope.resolve.count
  end
end
