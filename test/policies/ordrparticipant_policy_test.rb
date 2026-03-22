require 'test_helper'

# OrdrparticipantPolicy: create/update allow anonymous customers via user.id.nil? check.
# destroy requires ownership. index checks user.present? (always true).
class OrdrparticipantPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @ordrparticipant = ordrparticipants(:one)
    # User.new (no id) simulates the anonymous customer path
    @anon_user = User.new
  end

  test 'index is allowed for authenticated user' do
    policy = OrdrparticipantPolicy.new(@owner, @ordrparticipant)
    assert policy.index?
  end

  test 'index is allowed for guest (user.present? always true)' do
    policy = OrdrparticipantPolicy.new(nil, @ordrparticipant)
    assert policy.index?
  end

  test 'create is allowed for anonymous customers (User.new has no id)' do
    policy = OrdrparticipantPolicy.new(@anon_user, @ordrparticipant)
    assert policy.create?
  end

  test 'create is allowed for authenticated user' do
    policy = OrdrparticipantPolicy.new(@owner, @ordrparticipant)
    assert policy.create?
  end

  test 'update is allowed for anonymous customers (User.new has no id)' do
    policy = OrdrparticipantPolicy.new(@anon_user, @ordrparticipant)
    assert policy.update?
  end

  test 'update is allowed for owner' do
    policy = OrdrparticipantPolicy.new(@owner, @ordrparticipant)
    assert policy.update?
  end

  test 'update is denied for non-owner authenticated user' do
    policy = OrdrparticipantPolicy.new(@other_user, @ordrparticipant)
    assert_not policy.update?
  end

  test 'destroy is allowed for owner' do
    policy = OrdrparticipantPolicy.new(@owner, @ordrparticipant)
    assert policy.destroy?
  end

  test 'destroy is denied for non-owner' do
    policy = OrdrparticipantPolicy.new(@other_user, @ordrparticipant)
    assert_not policy.destroy?
  end

  test 'inherits from ApplicationPolicy' do
    assert OrdrparticipantPolicy < ApplicationPolicy
  end

  test 'scope returns none for guest user (no restaurants)' do
    scope = OrdrparticipantPolicy::Scope.new(nil, Ordrparticipant.all)
    assert_equal 0, scope.resolve.count
  end

  test 'show is allowed for owner' do
    policy = OrdrparticipantPolicy.new(@owner, @ordrparticipant)
    assert policy.show?
  end

  test 'show is denied for non-owner' do
    policy = OrdrparticipantPolicy.new(@other_user, @ordrparticipant)
    assert_not policy.show?
  end
end
