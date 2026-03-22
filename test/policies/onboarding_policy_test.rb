require 'test_helper'

class OnboardingPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @session = onboarding_sessions(:one)
  end

  test 'show is allowed for session owner' do
    policy = OnboardingPolicy.new(@user, @session)
    assert policy.show?
  end

  test 'show is denied for non-owner' do
    policy = OnboardingPolicy.new(@other_user, @session)
    assert_not policy.show?
  end

  test 'update is allowed for session owner' do
    policy = OnboardingPolicy.new(@user, @session)
    assert policy.update?
  end

  test 'update is denied for non-owner' do
    policy = OnboardingPolicy.new(@other_user, @session)
    assert_not policy.update?
  end

  test 'inherits from ApplicationPolicy' do
    assert OnboardingPolicy < ApplicationPolicy
  end

  test 'scope resolves to own sessions only' do
    scope = OnboardingPolicy::Scope.new(@user, OnboardingSession.all)
    result = scope.resolve
    result.each do |session|
      assert_equal @user.id, session.user_id
    end
  end
end
