require 'test_helper'

# OrdritemPolicy:
# index? — user.present? (always true via User.new coercion)
# show?/edit?/update?/destroy? — true unless user.persisted? (anonymous), else owner?
#   owner? checks record.ordr.restaurant.user_id == user.id
# new?/create? — true unless user.persisted? (anonymous), else user.persisted?
# Scope — joins ordr -> restaurant, filters by restaurant.user_id
class OrdritemPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @anon_user = User.new # unpersisted — simulates anonymous customer
    @ordritem = ordritems(:one) # ordr: one -> restaurant: one (owned by users(:one))
  end

  test 'index is allowed for authenticated user' do
    policy = OrdritemPolicy.new(@owner, @ordritem)
    assert policy.index?
  end

  test 'index is allowed for nil user (User.new coercion)' do
    policy = OrdritemPolicy.new(nil, @ordritem)
    assert policy.index?
  end

  test 'show is allowed for anonymous customer (unpersisted user)' do
    policy = OrdritemPolicy.new(@anon_user, @ordritem)
    assert policy.show?
  end

  test 'show is allowed for owner' do
    policy = OrdritemPolicy.new(@owner, @ordritem)
    assert policy.show?
  end

  test 'show is denied for authenticated non-owner' do
    policy = OrdritemPolicy.new(@other_user, @ordritem)
    assert_not policy.show?
  end

  test 'new is allowed for anonymous customer' do
    policy = OrdritemPolicy.new(@anon_user, @ordritem)
    assert policy.new?
  end

  test 'new is allowed for authenticated user' do
    policy = OrdritemPolicy.new(@owner, @ordritem)
    assert policy.new?
  end

  test 'create is allowed for anonymous customer' do
    policy = OrdritemPolicy.new(@anon_user, @ordritem)
    assert policy.create?
  end

  test 'create is allowed for authenticated user' do
    policy = OrdritemPolicy.new(@owner, @ordritem)
    assert policy.create?
  end

  test 'edit is allowed for anonymous customer' do
    policy = OrdritemPolicy.new(@anon_user, @ordritem)
    assert policy.edit?
  end

  test 'edit is allowed for owner' do
    policy = OrdritemPolicy.new(@owner, @ordritem)
    assert policy.edit?
  end

  test 'edit is denied for authenticated non-owner' do
    policy = OrdritemPolicy.new(@other_user, @ordritem)
    assert_not policy.edit?
  end

  test 'update is allowed for anonymous customer' do
    policy = OrdritemPolicy.new(@anon_user, @ordritem)
    assert policy.update?
  end

  test 'update is allowed for owner' do
    policy = OrdritemPolicy.new(@owner, @ordritem)
    assert policy.update?
  end

  test 'update is denied for authenticated non-owner' do
    policy = OrdritemPolicy.new(@other_user, @ordritem)
    assert_not policy.update?
  end

  test 'destroy is allowed for anonymous customer' do
    policy = OrdritemPolicy.new(@anon_user, @ordritem)
    assert policy.destroy?
  end

  test 'destroy is allowed for owner' do
    policy = OrdritemPolicy.new(@owner, @ordritem)
    assert policy.destroy?
  end

  test 'destroy is denied for authenticated non-owner' do
    policy = OrdritemPolicy.new(@other_user, @ordritem)
    assert_not policy.destroy?
  end

  test 'scope returns ordritems for user restaurants' do
    scope = OrdritemPolicy::Scope.new(@owner, Ordritem.all)
    result = scope.resolve
    owner_restaurant_ids = @owner.restaurants.pluck(:id)
    result.each do |item|
      assert_includes owner_restaurant_ids, item.ordr.restaurant_id
    end
  end

  test 'inherits from ApplicationPolicy' do
    assert OrdritemPolicy < ApplicationPolicy
  end
end
