require 'test_helper'

# OrdritemnotePolicy: index/create check user.present? (always true via User.new).
# show/update/destroy check user.present? AND owns_order_item_note? (restaurant ownership).
class OrdritemnotesPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)

    @ordritem = ordritems(:one)
    @ordritemnote = Ordritemnote.create!(
      ordritem: @ordritem,
      note: 'Test note',
    )
  end

  test 'index is allowed for authenticated user' do
    policy = OrdritemnotePolicy.new(@owner, @ordritemnote)
    assert policy.index?
  end

  test 'index is allowed for guest (user.present? always true)' do
    policy = OrdritemnotePolicy.new(nil, @ordritemnote)
    assert policy.index?
  end

  test 'create is allowed for authenticated user' do
    policy = OrdritemnotePolicy.new(@owner, @ordritemnote)
    assert policy.create?
  end

  test 'create is denied for guest (not an owner)' do
    policy = OrdritemnotePolicy.new(nil, @ordritemnote)
    assert_not policy.create?
  end

  test 'show is allowed for owner' do
    policy = OrdritemnotePolicy.new(@owner, @ordritemnote)
    assert policy.show?
  end

  test 'show is denied for non-owner' do
    policy = OrdritemnotePolicy.new(@other_user, @ordritemnote)
    assert_not policy.show?
  end

  test 'update is allowed for owner' do
    policy = OrdritemnotePolicy.new(@owner, @ordritemnote)
    assert policy.update?
  end

  test 'update is denied for non-owner' do
    policy = OrdritemnotePolicy.new(@other_user, @ordritemnote)
    assert_not policy.update?
  end

  test 'destroy is allowed for owner' do
    policy = OrdritemnotePolicy.new(@owner, @ordritemnote)
    assert policy.destroy?
  end

  test 'destroy is denied for non-owner' do
    policy = OrdritemnotePolicy.new(@other_user, @ordritemnote)
    assert_not policy.destroy?
  end

  test 'inherits from ApplicationPolicy' do
    assert OrdritemnotePolicy < ApplicationPolicy
  end

  test 'scope returns none for guest user (no restaurants)' do
    scope = OrdritemnotePolicy::Scope.new(nil, Ordritemnote.all)
    assert_equal 0, scope.resolve.count
  end
end
