require 'test_helper'

# MenuparticipantPolicy:
# index? checks user.present? (always true via User.new)
# show?/create?/update? return true unless user.persisted? (i.e., allow anonymous customers)
# destroy? requires owner? (restaurant ownership)
class MenuparticipantPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @menuparticipant = menuparticipants(:one)
    @anon_user = User.new  # unsaved, simulates anonymous customer
  end

  test 'index is allowed for authenticated user' do
    policy = MenuparticipantPolicy.new(@owner, @menuparticipant)
    assert policy.index?
  end

  test 'index is allowed for guest (user.present? always true)' do
    policy = MenuparticipantPolicy.new(nil, @menuparticipant)
    assert policy.index?
  end

  test 'create is allowed for anonymous customers (unpersisted user)' do
    policy = MenuparticipantPolicy.new(@anon_user, @menuparticipant)
    assert policy.create?
  end

  test 'create is allowed for authenticated user' do
    policy = MenuparticipantPolicy.new(@owner, @menuparticipant)
    assert policy.create?
  end

  test 'show is allowed for anonymous customers (unpersisted user)' do
    policy = MenuparticipantPolicy.new(@anon_user, @menuparticipant)
    assert policy.show?
  end

  test 'show is allowed for owner' do
    policy = MenuparticipantPolicy.new(@owner, @menuparticipant)
    assert policy.show?
  end

  test 'update is allowed for anonymous customers (unpersisted user)' do
    policy = MenuparticipantPolicy.new(@anon_user, @menuparticipant)
    assert policy.update?
  end

  test 'update is allowed for owner' do
    policy = MenuparticipantPolicy.new(@owner, @menuparticipant)
    assert policy.update?
  end

  test 'destroy is allowed for owner' do
    policy = MenuparticipantPolicy.new(@owner, @menuparticipant)
    assert policy.destroy?
  end

  test 'destroy is denied for non-owner' do
    policy = MenuparticipantPolicy.new(@other_user, @menuparticipant)
    assert_not policy.destroy?
  end

  test 'inherits from ApplicationPolicy' do
    assert MenuparticipantPolicy < ApplicationPolicy
  end
end
