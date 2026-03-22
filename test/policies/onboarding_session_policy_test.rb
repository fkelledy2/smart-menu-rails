require 'test_helper'

# OnboardingSessionPolicy:
# show?/update? — record.user == user (exact user match)
# Scope         — filters to sessions belonging to user
class OnboardingSessionPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @session = onboarding_sessions(:one)   # user: one
    @other_session = onboarding_sessions(:two) # user: two
  end

  test 'show is allowed for session owner' do
    policy = OnboardingSessionPolicy.new(@owner, @session)
    assert policy.show?
  end

  test 'show is denied for non-owner' do
    policy = OnboardingSessionPolicy.new(@other_user, @session)
    assert_not policy.show?
  end

  test 'update is allowed for session owner' do
    policy = OnboardingSessionPolicy.new(@owner, @session)
    assert policy.update?
  end

  test 'update is denied for non-owner' do
    policy = OnboardingSessionPolicy.new(@other_user, @session)
    assert_not policy.update?
  end

  test 'scope returns only sessions for the given user' do
    scope = OnboardingSessionPolicy::Scope.new(@owner, OnboardingSession.all)
    result = scope.resolve
    result.each do |s|
      assert_equal @owner.id, s.user_id
    end
  end

  test 'inherits from ApplicationPolicy' do
    assert OnboardingSessionPolicy < ApplicationPolicy
  end
end
