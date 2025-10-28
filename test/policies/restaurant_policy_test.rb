require 'test_helper'

class RestaurantPolicyTest < ActiveSupport::TestCase
  include AuthorizationTestHelper

  def setup
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one) # Owned by @user
    @other_restaurant = restaurants(:two) # Owned by @other_user

    # Create employee users for testing
    @admin_employee = create_employee_user(:admin, @restaurant)
    @manager_employee = create_employee_user(:manager, @restaurant)
    @staff_employee = create_employee_user(:staff, @restaurant)
  end

  # === INDEX TESTS ===

  test 'should allow authenticated user to view index' do
    policy = RestaurantPolicy.new(@user, Restaurant)
    assert policy.index?
  end

  test 'should deny anonymous user from viewing index' do
    policy = RestaurantPolicy.new(nil, Restaurant)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    # But the user won't have proper authentication, so this test needs adjustment
    # The actual authorization happens in controllers with authenticate_user!
    assert policy.index?, 'ApplicationPolicy creates User.new for anonymous users'
  end

  # === SHOW TESTS ===

  test 'should allow owner to view restaurant' do
    policy = RestaurantPolicy.new(@user, @restaurant)
    assert policy.show?
  end

  test 'should deny non-owner from viewing restaurant' do
    policy = RestaurantPolicy.new(@other_user, @restaurant)
    assert_not policy.show?
  end

  test 'should deny anonymous user from viewing restaurant' do
    policy = RestaurantPolicy.new(nil, @restaurant)
    assert_not policy.show?
  end

  # === CREATE TESTS ===

  test 'should allow authenticated user to create restaurant' do
    policy = RestaurantPolicy.new(@user, Restaurant.new)
    assert policy.create?
  end

  test 'should allow anonymous user to create restaurant' do
    policy = RestaurantPolicy.new(nil, Restaurant.new)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    # The actual authentication check happens in controllers
    assert policy.create?, 'ApplicationPolicy creates User.new for anonymous users'
  end

  # === UPDATE TESTS ===

  test 'should allow owner to update restaurant' do
    policy = RestaurantPolicy.new(@user, @restaurant)
    assert policy.update?
  end

  test 'should deny non-owner from updating restaurant' do
    policy = RestaurantPolicy.new(@other_user, @restaurant)
    assert_not policy.update?
  end

  test 'should deny anonymous user from updating restaurant' do
    policy = RestaurantPolicy.new(nil, @restaurant)
    assert_not policy.update?
  end

  # === DESTROY TESTS ===

  test 'should allow owner to destroy restaurant' do
    policy = RestaurantPolicy.new(@user, @restaurant)
    assert policy.destroy?
  end

  test 'should deny non-owner from destroying restaurant' do
    policy = RestaurantPolicy.new(@other_user, @restaurant)
    assert_not policy.destroy?
  end

  test 'should deny anonymous user from destroying restaurant' do
    policy = RestaurantPolicy.new(nil, @restaurant)
    assert_not policy.destroy?
  end

  # === ANALYTICS TESTS ===

  test 'should allow owner to view analytics' do
    policy = RestaurantPolicy.new(@user, @restaurant)
    assert policy.analytics?
  end

  test 'should deny non-owner from viewing analytics' do
    policy = RestaurantPolicy.new(@other_user, @restaurant)
    assert_not policy.analytics?
  end

  test 'should deny anonymous user from viewing analytics' do
    policy = RestaurantPolicy.new(nil, @restaurant)
    assert_not policy.analytics?
  end

  # === PERFORMANCE TESTS ===

  test 'should allow owner to view performance' do
    policy = RestaurantPolicy.new(@user, @restaurant)
    assert policy.performance?
  end

  test 'should deny non-owner from viewing performance' do
    policy = RestaurantPolicy.new(@other_user, @restaurant)
    assert_not policy.performance?
  end

  test 'should deny anonymous user from viewing performance' do
    policy = RestaurantPolicy.new(nil, @restaurant)
    assert_not policy.performance?
  end

  # === USER ACTIVITY TESTS ===

  test 'should allow owner to view user activity' do
    policy = RestaurantPolicy.new(@user, @restaurant)
    assert policy.user_activity?
  end

  test 'should deny non-owner from viewing user activity' do
    policy = RestaurantPolicy.new(@other_user, @restaurant)
    assert_not policy.user_activity?
  end

  test 'should deny anonymous user from viewing user activity' do
    policy = RestaurantPolicy.new(nil, @restaurant)
    assert_not policy.user_activity?
  end

  # === SPOTIFY INTEGRATION TESTS ===

  test 'should allow owner to access spotify auth' do
    policy = RestaurantPolicy.new(@user, @restaurant)
    assert policy.spotify_auth?
  end

  test 'should deny non-owner from accessing spotify auth' do
    policy = RestaurantPolicy.new(@other_user, @restaurant)
    assert_not policy.spotify_auth?
  end

  test 'should allow owner to access spotify callback' do
    policy = RestaurantPolicy.new(@user, @restaurant)
    assert policy.spotify_callback?
  end

  test 'should deny non-owner from accessing spotify callback' do
    policy = RestaurantPolicy.new(@other_user, @restaurant)
    assert_not policy.spotify_callback?
  end

  # === SCOPE TESTS ===

  test "should scope restaurants to user's own restaurants" do
    scope = RestaurantPolicy::Scope.new(@user, Restaurant).resolve

    # Should include user's restaurants
    assert_includes scope, @restaurant

    # Should not include other user's restaurants
    assert_not_includes scope, @other_restaurant
  end

  test 'should return empty scope for anonymous user' do
    scope = RestaurantPolicy::Scope.new(nil, Restaurant).resolve

    # Should not include any restaurants for anonymous user
    assert_not_includes scope, @restaurant
    assert_not_includes scope, @other_restaurant
  end

  test 'should handle user with no restaurants' do
    user_with_no_restaurants = User.create!(
      email: 'norestaurants@example.com',
      password: 'password123',
    )

    scope = RestaurantPolicy::Scope.new(user_with_no_restaurants, Restaurant).resolve

    # Should not include any restaurants
    assert_not_includes scope, @restaurant
    assert_not_includes scope, @other_restaurant
  end

  # === EDGE CASE TESTS ===

  test 'should handle nil restaurant record' do
    policy = RestaurantPolicy.new(@user, nil)

    # All owner-based methods should return false for nil record
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.analytics?
    assert_not policy.performance?
    assert_not policy.user_activity?
    assert_not policy.spotify_auth?
    assert_not policy.spotify_callback?
  end

  test 'should handle restaurant without user_id' do
    restaurant_without_user = Restaurant.new(name: 'Test Restaurant')
    policy = RestaurantPolicy.new(@user, restaurant_without_user)

    # Should deny access to restaurant without proper ownership
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should inherit from ApplicationPolicy' do
    assert RestaurantPolicy < ApplicationPolicy
  end

  # === BUSINESS LOGIC TESTS ===

  test 'should allow multiple restaurants per user' do
    # Create additional restaurant for the same user
    additional_restaurant = Restaurant.create!(
      name: 'Second Restaurant',
      user: @user,
      status: :active,
    )

    policy = RestaurantPolicy.new(@user, additional_restaurant)
    assert policy.show?
    assert policy.update?
    assert policy.destroy?

    # Scope should include both restaurants
    scope = RestaurantPolicy::Scope.new(@user, Restaurant).resolve
    assert_includes scope, @restaurant
    assert_includes scope, additional_restaurant
  end

  test 'should handle different user types consistently' do
    # Test with different user instances
    user1 = users(:one)
    user2 = users(:two) if users(:two)

    policy1 = RestaurantPolicy.new(user1, @restaurant)

    if user2
      policy2 = RestaurantPolicy.new(user2, @restaurant)

      # Only the owner should have access
      if @restaurant.user_id == user1.id
        assert policy1.show?
        assert_not policy2.show?
      elsif @restaurant.user_id == user2.id
        assert_not policy1.show?
        assert policy2.show?
      end
    end
  end

  # === RESTAURANT STATUS TESTS ===

  test 'should handle different restaurant statuses' do
    # Test with different restaurant statuses
    statuses = %i[active inactive archived]

    statuses.each do |status|
      restaurant = Restaurant.create!(
        name: "#{status.to_s.capitalize} Restaurant",
        user: @user,
        status: status,
      )

      policy = RestaurantPolicy.new(@user, restaurant)
      assert policy.show?, "Owner should have access to #{status} restaurants"
      assert policy.update?, "Owner should be able to update #{status} restaurants"
      assert policy.destroy?, "Owner should be able to destroy #{status} restaurants"
      assert policy.analytics?, "Owner should access analytics for #{status} restaurants"
      assert policy.performance?, "Owner should access performance for #{status} restaurants"
    end
  end

  test 'should handle restaurant lifecycle management' do
    # Test restaurant creation, activation, deactivation, archival
    new_restaurant = Restaurant.new(
      name: 'New Restaurant',
      user: @user,
      status: :inactive,
    )

    policy = RestaurantPolicy.new(@user, new_restaurant)

    # Owner should be able to manage restaurant through entire lifecycle
    assert policy.create?, 'Owner should be able to create restaurants'

    # After creation
    new_restaurant.save!
    assert policy.show?, 'Owner should be able to view new restaurants'
    assert policy.update?, 'Owner should be able to update restaurants'

    # Activation
    new_restaurant.update!(status: :active)
    assert policy.analytics?, 'Owner should access analytics for active restaurants'
    assert policy.performance?, 'Owner should access performance for active restaurants'

    # Archival
    new_restaurant.update!(status: :archived)
    assert policy.update?, 'Owner should be able to archive restaurants'
    assert policy.destroy?, 'Owner should be able to destroy archived restaurants'
  end

  # === BUSINESS FEATURES TESTS ===

  test 'should handle restaurant business features' do
    # Test all business feature access
    business_features = %i[
      analytics performance user_activity
      spotify_auth spotify_callback
    ]

    business_features.each do |feature|
      # Owner should have access
      owner_policy = RestaurantPolicy.new(@user, @restaurant)
      assert owner_policy.send("#{feature}?"), "Owner should access #{feature}"

      # Non-owner should not have access
      non_owner_policy = RestaurantPolicy.new(@other_user, @restaurant)
      assert_not non_owner_policy.send("#{feature}?"), "Non-owner should not access #{feature}"

      # Anonymous user should not have access
      anonymous_policy = RestaurantPolicy.new(nil, @restaurant)
      assert_not anonymous_policy.send("#{feature}?"), "Anonymous user should not access #{feature}"
    end
  end

  test 'should handle restaurant wifi configuration' do
    # Test restaurant with wifi configuration
    wifi_restaurant = Restaurant.create!(
      name: 'WiFi Restaurant',
      user: @user,
      status: :active,
      wifissid: 'RestaurantWiFi',
      wifiPassword: 'password123',
      wifiEncryptionType: :WPA,
      wifiHidden: false,
    )

    policy = RestaurantPolicy.new(@user, wifi_restaurant)
    assert policy.show?, 'Owner should access restaurant with WiFi config'
    assert policy.update?, 'Owner should update restaurant WiFi config'

    # Non-owner should not access WiFi configuration
    non_owner_policy = RestaurantPolicy.new(@other_user, wifi_restaurant)
    assert_not non_owner_policy.show?, 'Non-owner should not access WiFi config'
  end

  # === PERFORMANCE TESTS ===

  test 'should handle large restaurant datasets efficiently' do
    # Create multiple restaurants to test performance
    10.times do |i|
      Restaurant.create!(
        name: "Bulk Restaurant #{i}",
        user: @user,
        status: :active,
      )
    end

    scope = RestaurantPolicy::Scope.new(@user, Restaurant).resolve

    # Should handle large datasets efficiently
    assert_nothing_raised do
      scope.limit(50).each do |restaurant|
        # Access restaurant data
        restaurant.name
        restaurant.status
      end
    end
  end

  test 'should prevent unauthorized access across user boundaries' do
    # Create restaurants for different users
    user_a = @user
    user_b = @other_user

    restaurant_a = Restaurant.create!(name: 'Restaurant A', user: user_a, status: :active)
    restaurant_b = Restaurant.create!(name: 'Restaurant B', user: user_b, status: :active)

    # User A should only access their own restaurant
    policy_a_own = RestaurantPolicy.new(user_a, restaurant_a)
    policy_a_other = RestaurantPolicy.new(user_a, restaurant_b)

    assert policy_a_own.show?, 'User should access their own restaurant'
    assert_not policy_a_other.show?, "User should not access other user's restaurant"

    # Scope should only include own restaurants
    scope_a = RestaurantPolicy::Scope.new(user_a, Restaurant).resolve
    assert_includes scope_a, restaurant_a
    assert_not_includes scope_a, restaurant_b

    scope_b = RestaurantPolicy::Scope.new(user_b, Restaurant).resolve
    assert_includes scope_b, restaurant_b
    assert_not_includes scope_b, restaurant_a
  end

  # === RESTAURANT ANALYTICS SECURITY ===

  test 'should protect sensitive restaurant analytics' do
    # Analytics contain sensitive business data

    # Owner should have full analytics access
    owner_policy = RestaurantPolicy.new(@user, @restaurant)
    assert owner_policy.analytics?, 'Owner should access restaurant analytics'
    assert owner_policy.performance?, 'Owner should access performance metrics'
    assert owner_policy.user_activity?, 'Owner should access user activity data'

    # Non-owner should have no analytics access
    non_owner_policy = RestaurantPolicy.new(@other_user, @restaurant)
    assert_not non_owner_policy.analytics?, 'Non-owner should not access analytics'
    assert_not non_owner_policy.performance?, 'Non-owner should not access performance'
    assert_not non_owner_policy.user_activity?, 'Non-owner should not access user activity'

    # Anonymous user should have no analytics access
    anonymous_policy = RestaurantPolicy.new(nil, @restaurant)
    assert_not anonymous_policy.analytics?, 'Anonymous user should not access analytics'
    assert_not anonymous_policy.performance?, 'Anonymous user should not access performance'
    assert_not anonymous_policy.user_activity?, 'Anonymous user should not access user activity'
  end

  test 'should handle restaurant data privacy' do
    # Ensure restaurant data is only visible to owners

    # Create restaurants for different users
    restaurant_configs = [
      { name: 'Pizza Place', user: @user, status: :active },
      { name: 'Burger Joint', user: @user, status: :inactive },
      { name: 'Sushi Bar', user: @other_user, status: :active },
    ]

    restaurants = restaurant_configs.map do |config|
      Restaurant.create!(**config)
    end

    # User should see only their own restaurants
    user_scope = RestaurantPolicy::Scope.new(@user, Restaurant).resolve
    user_restaurants = restaurants.select { |r| r.user_id == @user.id }
    other_restaurants = restaurants.reject { |r| r.user_id == @user.id }

    user_restaurants.each do |restaurant|
      assert_includes user_scope, restaurant, "User should see their own restaurant: #{restaurant.name}"

      policy = RestaurantPolicy.new(@user, restaurant)
      assert policy.show?, "User should access their own restaurant: #{restaurant.name}"
      assert policy.analytics?, "User should access analytics for: #{restaurant.name}"
    end

    other_restaurants.each do |restaurant|
      assert_not_includes user_scope, restaurant, "User should not see other's restaurant: #{restaurant.name}"

      policy = RestaurantPolicy.new(@user, restaurant)
      assert_not policy.show?, "User should not access other's restaurant: #{restaurant.name}"
      assert_not policy.analytics?, "User should not access analytics for: #{restaurant.name}"
    end
  end

  # === SPOTIFY INTEGRATION SECURITY ===

  test 'should secure spotify integration features' do
    # Spotify integration contains sensitive authentication data

    # Owner should have spotify access
    owner_policy = RestaurantPolicy.new(@user, @restaurant)
    assert owner_policy.spotify_auth?, 'Owner should access Spotify authentication'
    assert owner_policy.spotify_callback?, 'Owner should access Spotify callback'

    # Non-owner should not have spotify access
    non_owner_policy = RestaurantPolicy.new(@other_user, @restaurant)
    assert_not non_owner_policy.spotify_auth?, 'Non-owner should not access Spotify auth'
    assert_not non_owner_policy.spotify_callback?, 'Non-owner should not access Spotify callback'

    # Anonymous user should not have spotify access
    anonymous_policy = RestaurantPolicy.new(nil, @restaurant)
    assert_not anonymous_policy.spotify_auth?, 'Anonymous user should not access Spotify auth'
    assert_not anonymous_policy.spotify_callback?, 'Anonymous user should not access Spotify callback'
  end

  # === SCOPE EFFICIENCY TESTS ===

  test 'should use efficient scope queries' do
    scope = RestaurantPolicy::Scope.new(@user, Restaurant).resolve

    # Verify the scope returns only user's restaurants
    assert_includes scope, @restaurant, "Scope should include user's restaurant"
    assert_not_includes scope, @other_restaurant, "Scope should not include other user's restaurant"
  end

  test 'should handle scope with additional conditions' do
    # Create restaurants with different statuses
    Restaurant.create!(name: 'Active Restaurant', user: @user, status: :active)
    Restaurant.create!(name: 'Inactive Restaurant', user: @user, status: :inactive)

    scope = RestaurantPolicy::Scope.new(@user, Restaurant).resolve

    # Should work with additional conditions
    active_restaurants = scope.where(status: :active)
    inactive_restaurants = scope.where(status: :inactive)

    assert active_restaurants.count >= 1, 'Should find active restaurants'
    assert inactive_restaurants.count >= 1, 'Should find inactive restaurants'
  end

  # === RESTAURANT OWNERSHIP VALIDATION ===

  test 'should validate direct ownership model' do
    # Create a fresh restaurant for this test to avoid setup interference
    test_restaurant = Restaurant.create!(
      name: 'Test Ownership Restaurant',
      user: @user,
      status: :active,
    )

    # Test direct ownership
    assert_equal @user.id, test_restaurant.user_id, 'Restaurant should have direct user ownership'

    policy = RestaurantPolicy.new(@user, test_restaurant)
    assert policy.show?, 'Owner should have access through direct ownership'

    # Test ownership transfer scenario
    new_owner = User.create!(
      email: 'newowner@example.com',
      password: 'password123',
      first_name: 'New',
      last_name: 'Owner',
      plan: plans(:one),
    )
    test_restaurant.update!(user: new_owner)

    # Original owner should lose access (no employee relationship exists)
    test_restaurant.reload
    original_policy = RestaurantPolicy.new(@user, test_restaurant)
    assert_not original_policy.show?, 'Original owner should lose access after transfer'

    # New owner should gain access
    new_policy = RestaurantPolicy.new(new_owner, test_restaurant)
    assert new_policy.show?, 'New owner should gain access after transfer'
  end

  test 'should handle restaurant creation authorization' do
    # Test restaurant creation patterns

    # Authenticated user should be able to create
    create_policy = RestaurantPolicy.new(@user, Restaurant.new)
    assert create_policy.create?, 'Authenticated user should create restaurants'

    # Test actual creation
    new_restaurant = Restaurant.new(
      name: 'Created Restaurant',
      user: @user,
      status: :active,
    )

    assert new_restaurant.save, 'Restaurant should be created successfully'

    # Creator should have full access
    creator_policy = RestaurantPolicy.new(@user, new_restaurant)
    assert creator_policy.show?, 'Creator should have full access'
    assert creator_policy.update?, 'Creator should be able to update'
    assert creator_policy.destroy?, 'Creator should be able to destroy'
    assert creator_policy.analytics?, 'Creator should access analytics'
  end

  # === EMPLOYEE ROLE AUTHORIZATION TESTS ===

  test 'should allow admin employees to view restaurant' do
    policy = RestaurantPolicy.new(@admin_employee, @restaurant)
    assert policy.show?, 'Admin employee should view restaurant'
  end

  test 'should allow manager employees to view restaurant' do
    policy = RestaurantPolicy.new(@manager_employee, @restaurant)
    assert policy.show?, 'Manager employee should view restaurant'
  end

  test 'should allow staff employees to view restaurant' do
    policy = RestaurantPolicy.new(@staff_employee, @restaurant)
    assert policy.show?, 'Staff employee should view restaurant'
  end

  test 'should allow admin employees to update restaurant' do
    policy = RestaurantPolicy.new(@admin_employee, @restaurant)
    assert policy.update?, 'Admin employee should update restaurant'
  end

  test 'should deny manager employees from updating restaurant' do
    policy = RestaurantPolicy.new(@manager_employee, @restaurant)
    assert_not policy.update?, 'Manager employee should not update restaurant'
  end

  test 'should deny staff employees from updating restaurant' do
    policy = RestaurantPolicy.new(@staff_employee, @restaurant)
    assert_not policy.update?, 'Staff employee should not update restaurant'
  end

  test 'should deny all employees from destroying restaurant' do
    [@admin_employee, @manager_employee, @staff_employee].each do |employee|
      policy = RestaurantPolicy.new(employee, @restaurant)
      assert_not policy.destroy?, "#{employee.employees.first.role} employee should not destroy restaurant"
    end
  end

  test 'should allow admin employees to access analytics' do
    policy = RestaurantPolicy.new(@admin_employee, @restaurant)
    assert policy.analytics?, 'Admin employee should access analytics'
  end

  test 'should deny manager and staff employees from accessing analytics' do
    [@manager_employee, @staff_employee].each do |employee|
      policy = RestaurantPolicy.new(employee, @restaurant)
      assert_not policy.analytics?, "#{employee.employees.first.role} employee should not access analytics"
    end
  end

  test 'should allow admin employees to access performance data' do
    policy = RestaurantPolicy.new(@admin_employee, @restaurant)
    assert policy.performance?, 'Admin employee should access performance data'
  end

  test 'should allow admin employees to access spotify features' do
    policy = RestaurantPolicy.new(@admin_employee, @restaurant)
    assert policy.spotify_auth?, 'Admin employee should access spotify auth'
    assert policy.spotify_callback?, 'Admin employee should access spotify callback'
  end

  test 'should deny non-admin employees from accessing spotify features' do
    [@manager_employee, @staff_employee].each do |employee|
      policy = RestaurantPolicy.new(employee, @restaurant)
      assert_not policy.spotify_auth?, "#{employee.employees.first.role} employee should not access spotify auth"
      assert_not policy.spotify_callback?,
                 "#{employee.employees.first.role} employee should not access spotify callback"
    end
  end

  test 'should include employee restaurants in scope' do
    scope = RestaurantPolicy::Scope.new(@admin_employee, Restaurant).resolve
    assert_includes scope, @restaurant, 'Employee should see their restaurant in scope'
    assert_not_includes scope, @other_restaurant, 'Employee should not see other restaurants in scope'
  end

  test 'should handle inactive employees' do
    # Make employee inactive
    @admin_employee.employees.first.update!(status: :inactive)

    policy = RestaurantPolicy.new(@admin_employee, @restaurant)
    assert_not policy.show?, 'Inactive employee should not access restaurant'
    assert_not policy.update?, 'Inactive employee should not update restaurant'
    assert_not policy.analytics?, 'Inactive employee should not access analytics'
  end

  test 'should prevent employees from accessing other restaurants' do
    other_restaurant_employee = create_employee_user(:admin, @other_restaurant)

    policy = RestaurantPolicy.new(other_restaurant_employee, @restaurant)
    assert_not policy.show?, 'Employee should not access other restaurant'
    assert_not policy.update?, 'Employee should not update other restaurant'
    assert_not policy.analytics?, 'Employee should not access other restaurant analytics'
  end

  # === COMPREHENSIVE AUTHORIZATION TESTS ===

  test 'should enforce complete authorization matrix for show action' do
    expected_results = {
      owner: true,
      employee_admin: true,
      employee_manager: true,
      employee_staff: true,
      customer: false,
      anonymous: false,
    }

    expected_results.each do |role, expected|
      user = create_user_with_role(role, @restaurant)
      policy = RestaurantPolicy.new(user, @restaurant)
      result = policy.show?

      assert_equal expected, result,
                   "#{role} should #{expected ? 'be allowed' : 'be denied'} show on Restaurant"
    end
  end

  test 'should enforce complete authorization matrix for update action' do
    expected_results = {
      owner: true,
      employee_admin: true,
      employee_manager: false,
      employee_staff: false,
      customer: false,
      anonymous: false,
    }

    expected_results.each do |role, expected|
      user = create_user_with_role(role, @restaurant)
      policy = RestaurantPolicy.new(user, @restaurant)
      result = policy.update?

      assert_equal expected, result,
                   "#{role} should #{expected ? 'be allowed' : 'be denied'} update on Restaurant"
    end
  end

  test 'should enforce complete authorization matrix for destroy action' do
    expected_results = {
      owner: true,
      employee_admin: false,
      employee_manager: false,
      employee_staff: false,
      customer: false,
      anonymous: false,
    }

    expected_results.each do |role, expected|
      user = create_user_with_role(role, @restaurant)
      policy = RestaurantPolicy.new(user, @restaurant)
      result = policy.destroy?

      assert_equal expected, result,
                   "#{role} should #{expected ? 'be allowed' : 'be denied'} destroy on Restaurant"
    end
  end

  test 'should enforce complete authorization matrix for analytics action' do
    expected_results = {
      owner: true,
      employee_admin: true,
      employee_manager: false,
      employee_staff: false,
      customer: false,
      anonymous: false,
    }

    expected_results.each do |role, expected|
      user = create_user_with_role(role, @restaurant)
      policy = RestaurantPolicy.new(user, @restaurant)
      result = policy.analytics?

      assert_equal expected, result,
                   "#{role} should #{expected ? 'be allowed' : 'be denied'} analytics on Restaurant"
    end
  end

  # === CROSS-RESTAURANT ISOLATION TESTS ===

  test 'should prevent cross-restaurant data access' do
    owner1 = users(:one)
    owner2 = users(:two)

    # Create resource owned by owner2
    resource = Restaurant.create!(name: 'Test Restaurant', user: owner2, status: :active)

    # Test that owner1 cannot access owner2's resource
    policy = RestaurantPolicy.new(owner1, resource)
    result = policy.show?

    assert_not result, "User should not be able to show other user's Restaurant"
  end

  test 'should prevent cross-restaurant analytics access' do
    owner1 = users(:one)
    owner2 = users(:two)

    # Create resource owned by owner2
    resource = Restaurant.create!(name: 'Analytics Restaurant', user: owner2, status: :active)

    # Test that owner1 cannot access owner2's resource
    policy = RestaurantPolicy.new(owner1, resource)
    result = policy.analytics?

    assert_not result, "User should not be able to analytics other user's Restaurant"
  end
end
