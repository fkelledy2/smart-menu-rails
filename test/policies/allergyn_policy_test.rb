require 'test_helper'

# AllergynPolicy: index? => true (public). create? => user.present? (always true via User.new).
# show/update/destroy check owner? which checks restaurant.user_id == user.id.
class AllergynPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @allergyn = allergyns(:one)  # belongs to restaurant :one, owned by user :one
  end

  test 'index is allowed publicly' do
    policy = AllergynPolicy.new(@owner, @allergyn)
    assert policy.index?
  end

  test 'index is allowed even for nil user (public)' do
    policy = AllergynPolicy.new(nil, @allergyn)
    assert policy.index?
  end

  test 'show is allowed for owner' do
    policy = AllergynPolicy.new(@owner, @allergyn)
    assert policy.show?
  end

  test 'show is denied for non-owner' do
    policy = AllergynPolicy.new(@other_user, @allergyn)
    assert_not policy.show?
  end

  test 'create is allowed for authenticated user' do
    policy = AllergynPolicy.new(@owner, @allergyn)
    assert policy.create?
  end

  test 'create is allowed for guest (user.present? is always true via User.new)' do
    policy = AllergynPolicy.new(nil, @allergyn)
    assert policy.create?
  end

  test 'update is allowed for owner' do
    policy = AllergynPolicy.new(@owner, @allergyn)
    assert policy.update?
  end

  test 'update is denied for non-owner' do
    policy = AllergynPolicy.new(@other_user, @allergyn)
    assert_not policy.update?
  end

  test 'destroy is allowed for owner' do
    policy = AllergynPolicy.new(@owner, @allergyn)
    assert policy.destroy?
  end

  test 'destroy is denied for non-owner' do
    policy = AllergynPolicy.new(@other_user, @allergyn)
    assert_not policy.destroy?
  end

  test 'inherits from ApplicationPolicy' do
    assert AllergynPolicy < ApplicationPolicy
  end

  test 'show is denied for guest user (no restaurant ownership)' do
    # User.new has no id, so user.id will be nil
    # owner? checks record.restaurant.user_id == user.id => nil == nil... but also
    # user must be present AND restaurant matches
    guest = User.new
    policy = AllergynPolicy.new(guest, @allergyn)
    # owner? returns false when user.id is nil and restaurant.user_id is set
    assert_not policy.show?
  end
end
