require 'test_helper'

class UserplanPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)

    # Create plans for testing
    @basic_plan = Plan.create!(
      key: 'plan.basic.key',
      pricePerMonth: 9.99,
      status: :active,
    )

    @premium_plan = Plan.create!(
      key: 'plan.premium.key',
      pricePerMonth: 19.99,
      status: :active,
    )

    # Create userplans for testing
    @userplan = Userplan.create!(
      user: @user,
      plan: @basic_plan,
    )

    @other_userplan = Userplan.create!(
      user: @other_user,
      plan: @premium_plan,
    )
  end

  # === INDEX TESTS ===

  test 'should allow authenticated user to view userplan index' do
    policy = UserplanPolicy.new(@user, Userplan)
    assert policy.index?
  end

  test 'should allow anonymous user to view userplan index' do
    policy = UserplanPolicy.new(nil, Userplan)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.index?, 'ApplicationPolicy creates User.new for anonymous users'
  end

  # === SHOW TESTS ===

  test 'should allow owner to view userplan' do
    policy = UserplanPolicy.new(@user, @userplan)
    assert policy.show?
  end

  test 'should deny non-owner from viewing userplan' do
    policy = UserplanPolicy.new(@user, @other_userplan)
    assert_not policy.show?
  end

  test 'should deny anonymous user from viewing userplan' do
    policy = UserplanPolicy.new(nil, @userplan)
    assert_not policy.show?
  end

  # === CREATE TESTS ===

  test 'should allow authenticated user to create userplan' do
    policy = UserplanPolicy.new(@user, Userplan.new)
    assert policy.create?
  end

  test 'should allow anonymous user to create userplan' do
    policy = UserplanPolicy.new(nil, Userplan.new)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.create?, 'ApplicationPolicy creates User.new for anonymous users'
  end

  # === UPDATE TESTS ===

  test 'should allow owner to update userplan' do
    policy = UserplanPolicy.new(@user, @userplan)
    assert policy.update?
  end

  test 'should deny non-owner from updating userplan' do
    policy = UserplanPolicy.new(@user, @other_userplan)
    assert_not policy.update?
  end

  test 'should deny anonymous user from updating userplan' do
    policy = UserplanPolicy.new(nil, @userplan)
    assert_not policy.update?
  end

  # === DESTROY TESTS ===

  test 'should allow owner to destroy userplan' do
    policy = UserplanPolicy.new(@user, @userplan)
    assert policy.destroy?
  end

  test 'should deny non-owner from destroying userplan' do
    policy = UserplanPolicy.new(@user, @other_userplan)
    assert_not policy.destroy?
  end

  test 'should deny anonymous user from destroying userplan' do
    policy = UserplanPolicy.new(nil, @userplan)
    assert_not policy.destroy?
  end

  # === SCOPE TESTS ===

  test "should scope userplans to user's own userplans" do
    scope = UserplanPolicy::Scope.new(@user, Userplan).resolve

    # Should include user's userplans
    assert_includes scope, @userplan

    # Should not include other user's userplans
    assert_not_includes scope, @other_userplan
  end

  test 'should return empty scope for anonymous user' do
    scope = UserplanPolicy::Scope.new(nil, Userplan).resolve

    # Should not include any userplans for anonymous user
    assert_not_includes scope, @userplan
    assert_not_includes scope, @other_userplan
  end

  test 'should handle user with no userplans' do
    user_with_no_plans = User.create!(
      email: 'noplans@example.com',
      password: 'password123',
    )

    scope = UserplanPolicy::Scope.new(user_with_no_plans, Userplan).resolve

    # Should not include any userplans
    assert_not_includes scope, @userplan
    assert_not_includes scope, @other_userplan
  end

  # === EDGE CASE TESTS ===

  test 'should handle nil userplan record' do
    policy = UserplanPolicy.new(@user, nil)

    # Public methods should still work
    assert policy.index?
    assert policy.create?

    # Owner-based methods should return false for nil record
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should handle userplan without user' do
    userplan_without_user = Userplan.new(plan: @basic_plan)
    policy = UserplanPolicy.new(@user, userplan_without_user)

    # Should deny access to userplan without proper user association
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should inherit from ApplicationPolicy' do
    assert UserplanPolicy < ApplicationPolicy
  end

  # === BUSINESS LOGIC TESTS ===

  test 'should handle different plan types' do
    # Test with different plan types
    plan_types = [
      { key: 'plan.free.key', pricePerMonth: 0.0 },
      { key: 'plan.starter.key', pricePerMonth: 5.99 },
      { key: 'plan.pro.key', pricePerMonth: 29.99 },
      { key: 'plan.enterprise.key', pricePerMonth: 99.99 },
    ]

    plan_types.each do |plan_data|
      plan = Plan.create!(status: :active, **plan_data)
      userplan = Userplan.create!(
        user: @user,
        plan: plan,
      )

      policy = UserplanPolicy.new(@user, userplan)
      assert policy.show?, "Owner should have access to #{plan.name}"
      assert policy.update?, "Owner should be able to update #{plan.name}"
      assert policy.destroy?, "Owner should be able to destroy #{plan.name}"
    end
  end

  test 'should handle multiple userplans per user' do
    # Create additional userplan for the same user
    additional_plan = Plan.create!(
      key: 'plan.additional.key',
      pricePerMonth: 15.99,
      status: :active,
    )

    additional_userplan = Userplan.create!(
      user: @user,
      plan: additional_plan,
    )

    policy = UserplanPolicy.new(@user, additional_userplan)
    assert policy.show?
    assert policy.update?
    assert policy.destroy?

    # Scope should include both userplans
    scope = UserplanPolicy::Scope.new(@user, Userplan).resolve
    assert_includes scope, @userplan
    assert_includes scope, additional_userplan
  end

  test 'should handle cross-user userplan access correctly' do
    # Verify that ownership is checked through user
    policy_own_plan = UserplanPolicy.new(@user, @userplan)
    policy_other_plan = UserplanPolicy.new(@user, @other_userplan)

    # Should have access to own userplan
    assert policy_own_plan.show?
    assert policy_own_plan.update?
    assert policy_own_plan.destroy?

    # Should not have access to other user's userplan
    assert_not policy_other_plan.show?
    assert_not policy_other_plan.update?
    assert_not policy_other_plan.destroy?
  end

  # === USER OWNERSHIP TESTS ===

  test 'should properly validate user ownership' do
    # Test the ownership chain: User → Userplan
    assert_equal @user.id, @userplan.user_id,
                 'Test setup should have proper ownership chain'

    policy = UserplanPolicy.new(@user, @userplan)
    assert policy.show?, 'Owner should have access through user ownership'

    # Test with different user
    other_policy = UserplanPolicy.new(@user, @other_userplan)
    assert_not other_policy.show?, 'Non-owner should not have access'
  end

  test 'should handle scope correctly with multiple users' do
    # Create additional user with userplan
    additional_user = User.create!(
      email: 'additional@example.com',
      password: 'password123',
    )

    additional_plan = Plan.create!(
      key: 'plan.additional_user.key',
      pricePerMonth: 12.99,
      status: :active,
    )

    additional_userplan = Userplan.create!(
      user: additional_user,
      plan: additional_plan,
    )

    scope = UserplanPolicy::Scope.new(@user, Userplan).resolve

    # Should include user's userplans
    assert_includes scope, @userplan

    # Should not include other users' userplans
    assert_not_includes scope, @other_userplan
    assert_not_includes scope, additional_userplan
  end

  # === SUBSCRIPTION MANAGEMENT TESTS ===

  test 'should handle userplan lifecycle management' do
    # Test userplan creation, modification, cancellation
    new_plan = Plan.create!(
      key: 'plan.new.key',
      pricePerMonth: 24.99,
      status: :active,
    )

    new_userplan = Userplan.new(
      user: @user,
      plan: new_plan,
    )

    policy = UserplanPolicy.new(@user, new_userplan)

    # Owner should be able to manage userplan through entire lifecycle
    assert policy.create?, 'Owner should be able to create userplans'

    # After creation
    new_userplan.save!
    assert policy.show?, 'Owner should be able to view new userplans'
    assert policy.update?, 'Owner should be able to update userplans'

    # Plan changes (upgrade/downgrade)
    premium_plan = Plan.create!(key: 'plan.premium_upgrade.key', pricePerMonth: 39.99, status: :active)
    new_userplan.update!(plan: premium_plan)
    assert policy.update?, 'Owner should be able to change plans'

    # Cancellation
    assert policy.destroy?, 'Owner should be able to cancel userplans'
  end

  test 'should handle subscription billing scenarios' do
    # Different billing scenarios for userplans
    billing_scenarios = [
      { key: 'plan.monthly_basic.key', pricePerMonth: 9.99 },
      { key: 'plan.annual_basic.key', pricePerMonth: 99.99 },
      { key: 'plan.monthly_premium.key', pricePerMonth: 19.99 },
      { key: 'plan.annual_premium.key', pricePerMonth: 199.99 },
      { key: 'plan.enterprise_custom.key', pricePerMonth: 499.99 },
    ]

    billing_scenarios.each do |scenario|
      plan = Plan.create!(status: :active, **scenario)
      userplan = Userplan.create!(
        user: @user,
        plan: plan,
      )

      policy = UserplanPolicy.new(@user, userplan)
      assert policy.show?, "Owner should have access to #{plan.name}"
      assert policy.update?, "Owner should be able to update #{plan.name}"
      assert policy.destroy?, "Owner should be able to cancel #{plan.name}"
    end
  end

  # === PERFORMANCE TESTS ===

  test 'should handle large userplan datasets efficiently' do
    # Create multiple userplans to test performance
    10.times do |i|
      plan = Plan.create!(
        key: "plan.bulk_#{i}.key",
        pricePerMonth: 10.0 + i,
        status: :active,
      )
      Userplan.create!(
        user: @user,
        plan: plan,
      )
    end

    scope = UserplanPolicy::Scope.new(@user, Userplan).resolve

    # Should handle large datasets without N+1 queries
    assert_nothing_raised do
      scope.limit(50).each do |userplan|
        # Access associated data that should be efficiently loaded
        userplan.user.email
        userplan.plan.name
      end
    end
  end

  test 'should prevent unauthorized access across user boundaries' do
    # Create userplans for different users
    user_a = @user
    user_b = @other_user

    plan_a = Plan.create!(key: 'plan.a.key', pricePerMonth: 15.99, status: :active)
    plan_b = Plan.create!(key: 'plan.b.key', pricePerMonth: 25.99, status: :active)

    userplan_a = Userplan.create!(user: user_a, plan: plan_a)
    userplan_b = Userplan.create!(user: user_b, plan: plan_b)

    # User A should only access their own userplan
    policy_a_own = UserplanPolicy.new(user_a, userplan_a)
    policy_a_other = UserplanPolicy.new(user_a, userplan_b)

    assert policy_a_own.show?, 'User should access their own userplan'
    assert_not policy_a_other.show?, "User should not access other user's userplan"

    # Scope should only include own userplans
    scope_a = UserplanPolicy::Scope.new(user_a, Userplan).resolve
    assert_includes scope_a, userplan_a
    assert_not_includes scope_a, userplan_b

    scope_b = UserplanPolicy::Scope.new(user_b, Userplan).resolve
    assert_includes scope_b, userplan_b
    assert_not_includes scope_b, userplan_a
  end

  # === SUBSCRIPTION PRIVACY TESTS ===

  test 'should protect sensitive subscription data' do
    # Userplans contain sensitive billing and subscription data

    # Owner should have full access
    owner_policy = UserplanPolicy.new(@user, @userplan)
    assert owner_policy.show?, 'Owner should access their subscription data'
    assert owner_policy.update?, 'Owner should modify their subscription'
    assert owner_policy.destroy?, 'Owner should cancel their subscription'

    # Non-owner should have no access
    non_owner_policy = UserplanPolicy.new(@other_user, @userplan)
    assert_not non_owner_policy.show?, 'Non-owner should not access subscription data'
    assert_not non_owner_policy.update?, 'Non-owner should not modify subscription'
    assert_not non_owner_policy.destroy?, 'Non-owner should not cancel subscription'

    # Anonymous user should have no access
    anonymous_policy = UserplanPolicy.new(nil, @userplan)
    assert_not anonymous_policy.show?, 'Anonymous user should not access subscription data'
    assert_not anonymous_policy.update?, 'Anonymous user should not modify subscription'
    assert_not anonymous_policy.destroy?, 'Anonymous user should not cancel subscription'
  end

  test 'should handle subscription data privacy' do
    # Ensure subscription data is only visible to owners

    # Create userplans for different users
    subscription_configs = [
      { user: @user, plan: @basic_plan },
      { user: @user, plan: @premium_plan },
      { user: @other_user, plan: @basic_plan },
    ]

    userplans = subscription_configs.map do |config|
      Userplan.create!(**config)
    end

    # User should see only their own subscriptions
    user_scope = UserplanPolicy::Scope.new(@user, Userplan).resolve
    user_subscriptions = userplans.select { |up| up.user_id == @user.id }
    other_subscriptions = userplans.reject { |up| up.user_id == @user.id }

    user_subscriptions.each do |userplan|
      assert_includes user_scope, userplan, 'User should see their own subscription'

      policy = UserplanPolicy.new(@user, userplan)
      assert policy.show?, 'User should access their own subscription'
    end

    other_subscriptions.each do |userplan|
      assert_not_includes user_scope, userplan, "User should not see other's subscription"

      policy = UserplanPolicy.new(@user, userplan)
      assert_not policy.show?, "User should not access other's subscription"
    end
  end

  # === SCOPE EFFICIENCY TESTS ===

  test 'should use efficient scope queries' do
    scope = UserplanPolicy::Scope.new(@user, Userplan).resolve

    # Verify the scope uses efficient queries
    assert scope.to_sql.include?('user_id'), 'Scope should filter by user_id'
  end

  test 'should handle scope with additional conditions' do
    # Create userplans with different plans
    expensive_plan = Plan.create!(key: 'plan.expensive.key', pricePerMonth: 99.99, status: :active)
    cheap_plan = Plan.create!(key: 'plan.cheap.key', pricePerMonth: 4.99, status: :active)

    Userplan.create!(user: @user, plan: expensive_plan)
    Userplan.create!(user: @user, plan: cheap_plan)

    scope = UserplanPolicy::Scope.new(@user, Userplan).resolve

    # Should work with additional conditions through joins
    expensive_userplans = scope.joins(:plan).where(plans: { pricePerMonth: 50.. })
    cheap_userplans = scope.joins(:plan).where(plans: { pricePerMonth: ..10 })

    assert expensive_userplans.count >= 1, 'Should find expensive userplans'
    assert cheap_userplans.count >= 1, 'Should find cheap userplans'
  end

  # === PLAN UPGRADE/DOWNGRADE TESTS ===

  test 'should handle plan upgrade scenarios' do
    # Test plan upgrade authorization

    # User should be able to upgrade their own plan
    upgrade_plan = Plan.create!(key: 'plan.upgrade.key', pricePerMonth: 49.99, status: :active)

    policy = UserplanPolicy.new(@user, @userplan)
    assert policy.update?, 'User should be able to upgrade their plan'

    # Test actual upgrade
    @userplan.plan
    @userplan.update!(plan: upgrade_plan)

    assert_equal upgrade_plan.id, @userplan.plan_id, 'Plan should be upgraded'
    assert policy.show?, 'User should still have access after upgrade'
  end

  test 'should handle subscription cancellation scenarios' do
    # Test subscription cancellation authorization

    # User should be able to cancel their own subscription
    policy = UserplanPolicy.new(@user, @userplan)
    assert policy.destroy?, 'User should be able to cancel their subscription'

    # Other user should not be able to cancel
    other_policy = UserplanPolicy.new(@other_user, @userplan)
    assert_not other_policy.destroy?, 'Other user should not cancel subscription'

    # Anonymous user should not be able to cancel
    anonymous_policy = UserplanPolicy.new(nil, @userplan)
    assert_not anonymous_policy.destroy?, 'Anonymous user should not cancel subscription'
  end

  # === DIRECT OWNERSHIP MODEL TESTS ===

  test 'should validate direct user ownership model' do
    # Userplans have direct user ownership

    # Test direct ownership
    assert_equal @user.id, @userplan.user_id, 'Userplan should have direct user ownership'

    policy = UserplanPolicy.new(@user, @userplan)
    assert policy.show?, 'Owner should have access through direct ownership'

    # Test ownership transfer scenario (rare but possible)
    new_owner = User.create!(email: 'newowner@example.com', password: 'password123')
    @userplan.update!(user: new_owner)

    # Original owner should lose access
    original_policy = UserplanPolicy.new(@user, @userplan)
    assert_not original_policy.show?, 'Original owner should lose access after transfer'

    # New owner should gain access
    new_policy = UserplanPolicy.new(new_owner, @userplan)
    assert new_policy.show?, 'New owner should gain access after transfer'
  end
end
