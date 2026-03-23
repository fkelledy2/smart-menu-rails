require 'test_helper'

# GenimagePolicy: index/create check user.present? (always true via User.new).
# show/update/destroy check owner? => restaurant.user_id == user.id
class GenimagePolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @genimage = genimages(:one) # belongs to restaurant :one => user :one
  end

  test 'index is allowed for authenticated user' do
    policy = GenimagePolicy.new(@owner, @genimage)
    assert policy.index?
  end

  test 'index is allowed for guest (user.present? is always true)' do
    policy = GenimagePolicy.new(nil, @genimage)
    assert policy.index?
  end

  test 'show is allowed for owner' do
    policy = GenimagePolicy.new(@owner, @genimage)
    assert policy.show?
  end

  test 'show is denied for non-owner' do
    policy = GenimagePolicy.new(@other_user, @genimage)
    assert_not policy.show?
  end

  test 'show is denied for guest (no restaurant ownership)' do
    policy = GenimagePolicy.new(nil, @genimage)
    assert_not policy.show?
  end

  test 'create is allowed for authenticated user' do
    policy = GenimagePolicy.new(@owner, @genimage)
    assert policy.create?
  end

  test 'create is allowed for guest (user.present? always true)' do
    policy = GenimagePolicy.new(nil, @genimage)
    assert policy.create?
  end

  test 'update is allowed for owner' do
    policy = GenimagePolicy.new(@owner, @genimage)
    assert policy.update?
  end

  test 'update is denied for non-owner' do
    policy = GenimagePolicy.new(@other_user, @genimage)
    assert_not policy.update?
  end

  test 'destroy is allowed for owner' do
    policy = GenimagePolicy.new(@owner, @genimage)
    assert policy.destroy?
  end

  test 'destroy is denied for non-owner' do
    policy = GenimagePolicy.new(@other_user, @genimage)
    assert_not policy.destroy?
  end

  test 'inherits from ApplicationPolicy' do
    assert GenimagePolicy < ApplicationPolicy
  end
end
