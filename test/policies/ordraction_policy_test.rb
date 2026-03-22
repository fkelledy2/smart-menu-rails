require 'test_helper'

# OrdractionPolicy: index/create check user.present? (always true via User.new).
# show/update/destroy check user.present? AND owns_order_action? (restaurant ownership).
class OrdractionPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)

    @ordr = ordrs(:one)
    @ordrparticipant = ordrparticipants(:one)

    @ordraction = Ordraction.create!(
      ordr: @ordr,
      ordrparticipant: @ordrparticipant,
      action: :participate,
    )
  end

  test 'index is allowed for authenticated user' do
    policy = OrdractionPolicy.new(@owner, @ordraction)
    assert policy.index?
  end

  test 'index is allowed for guest (user.present? always true)' do
    policy = OrdractionPolicy.new(nil, @ordraction)
    assert policy.index?
  end

  test 'create is allowed for authenticated user' do
    policy = OrdractionPolicy.new(@owner, @ordraction)
    assert policy.create?
  end

  test 'create is allowed for guest (user.present? always true)' do
    policy = OrdractionPolicy.new(nil, @ordraction)
    assert policy.create?
  end

  test 'show is allowed for owner of the order restaurant' do
    policy = OrdractionPolicy.new(@owner, @ordraction)
    assert policy.show?
  end

  test 'show is denied for non-owner' do
    policy = OrdractionPolicy.new(@other_user, @ordraction)
    assert_not policy.show?
  end

  test 'update is allowed for owner of the order restaurant' do
    policy = OrdractionPolicy.new(@owner, @ordraction)
    assert policy.update?
  end

  test 'update is denied for non-owner' do
    policy = OrdractionPolicy.new(@other_user, @ordraction)
    assert_not policy.update?
  end

  test 'destroy is allowed for owner of the order restaurant' do
    policy = OrdractionPolicy.new(@owner, @ordraction)
    assert policy.destroy?
  end

  test 'destroy is denied for non-owner' do
    policy = OrdractionPolicy.new(@other_user, @ordraction)
    assert_not policy.destroy?
  end

  test 'inherits from ApplicationPolicy' do
    assert OrdractionPolicy < ApplicationPolicy
  end

  test 'scope returns none for nil user (guest has no restaurants)' do
    scope = OrdractionPolicy::Scope.new(nil, Ordraction.all)
    # nil -> User.new which has no restaurants -> empty scope
    assert_equal 0, scope.resolve.count
  end

  test 'scope returns owner restaurant actions for authenticated user' do
    scope = OrdractionPolicy::Scope.new(@owner, Ordraction.all)
    result = scope.resolve
    result.each do |action|
      assert_equal @owner.id, action.ordr.restaurant.user_id
    end
  end
end
