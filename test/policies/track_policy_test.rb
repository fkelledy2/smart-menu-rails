require 'test_helper'

# TrackPolicy:
# index?/create?/new?  — user.present? (always true via User.new coercion)
# show?/update?/edit?/destroy? — user.present? && owns_track? (record.restaurant.user == user)
# Scope — joins :restaurant and filters by user; returns none for guest
class TrackPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @track = tracks(:one) # restaurant: one (owned by users(:one))
  end

  test 'index is allowed for authenticated user' do
    policy = TrackPolicy.new(@owner, @track)
    assert policy.index?
  end

  test 'index is allowed for nil user (User.new coercion)' do
    policy = TrackPolicy.new(nil, @track)
    assert policy.index?
  end

  test 'create is allowed for authenticated user' do
    policy = TrackPolicy.new(@owner, @track)
    assert policy.create?
  end

  test 'new delegates to create' do
    policy = TrackPolicy.new(@owner, @track)
    assert policy.new?
  end

  test 'show is allowed for track owner' do
    policy = TrackPolicy.new(@owner, @track)
    assert policy.show?
  end

  test 'show is denied for non-owner' do
    policy = TrackPolicy.new(@other_user, @track)
    assert_not policy.show?
  end

  test 'update is allowed for track owner' do
    policy = TrackPolicy.new(@owner, @track)
    assert policy.update?
  end

  test 'update is denied for non-owner' do
    policy = TrackPolicy.new(@other_user, @track)
    assert_not policy.update?
  end

  test 'edit delegates to update' do
    owner_policy = TrackPolicy.new(@owner, @track)
    other_policy = TrackPolicy.new(@other_user, @track)
    assert owner_policy.edit?
    assert_not other_policy.edit?
  end

  test 'destroy is allowed for track owner' do
    policy = TrackPolicy.new(@owner, @track)
    assert policy.destroy?
  end

  test 'destroy is denied for non-owner' do
    policy = TrackPolicy.new(@other_user, @track)
    assert_not policy.destroy?
  end

  test 'scope returns tracks for the given user' do
    scope = TrackPolicy::Scope.new(@owner, Track.all)
    result = scope.resolve
    result.each do |t|
      assert_equal @owner.id, t.restaurant.user_id
    end
  end

  test 'scope returns none for nil user' do
    scope = TrackPolicy::Scope.new(nil, Track.all)
    assert_empty scope.resolve
  end

  test 'inherits from ApplicationPolicy' do
    assert TrackPolicy < ApplicationPolicy
  end
end
