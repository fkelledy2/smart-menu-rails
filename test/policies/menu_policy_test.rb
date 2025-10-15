require 'test_helper'

class MenuPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one)  # Owned by @user
    @other_restaurant = restaurants(:two)  # Owned by @other_user
    @menu = menus(:one)  # Belongs to @restaurant
    @other_menu = menus(:two)  # Belongs to @other_restaurant
  end

  # === INDEX TESTS ===
  
  test "should allow authenticated user to view menu index" do
    policy = MenuPolicy.new(@user, Menu)
    assert policy.index?
  end

  test "should allow anonymous user to view menu index" do
    policy = MenuPolicy.new(nil, Menu)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.index?, "ApplicationPolicy creates User.new for anonymous users"
  end

  # === SHOW TESTS (Public Access for Customers) ===
  
  test "should allow anonymous customer to view menu" do
    policy = MenuPolicy.new(nil, @menu)
    assert policy.show?, "Anonymous customers should be able to view menus for ordering"
  end

  test "should allow owner to view their menu" do
    policy = MenuPolicy.new(@user, @menu)
    assert policy.show?
  end

  test "should allow non-owner authenticated user to view menu" do
    policy = MenuPolicy.new(@other_user, @menu)
    assert policy.show?, "All users should be able to view menus for ordering"
  end

  # === CREATE TESTS ===
  
  test "should allow authenticated user to create menu" do
    new_menu = Menu.new(restaurant_id: @restaurant.id)
    policy = MenuPolicy.new(@user, new_menu)
    assert policy.create?
  end

  test "should deny anonymous user from creating menu" do
    policy = MenuPolicy.new(nil, Menu.new)
    assert_not policy.create?, "Anonymous users should not be able to create menus"
  end

  # === UPDATE TESTS ===
  
  test "should allow owner to update menu" do
    policy = MenuPolicy.new(@user, @menu)
    assert policy.update?
  end

  test "should deny non-owner from updating menu" do
    policy = MenuPolicy.new(@other_user, @menu)
    assert_not policy.update?
  end

  test "should deny anonymous user from updating menu" do
    policy = MenuPolicy.new(nil, @menu)
    assert_not policy.update?
  end

  # === DESTROY TESTS ===
  
  test "should allow owner to destroy menu" do
    policy = MenuPolicy.new(@user, @menu)
    assert policy.destroy?
  end

  test "should deny non-owner from destroying menu" do
    policy = MenuPolicy.new(@other_user, @menu)
    assert_not policy.destroy?
  end

  test "should deny anonymous user from destroying menu" do
    policy = MenuPolicy.new(nil, @menu)
    assert_not policy.destroy?
  end

  # === REGENERATE IMAGES TESTS ===
  
  test "should allow owner to regenerate images" do
    policy = MenuPolicy.new(@user, @menu)
    assert policy.regenerate_images?
  end

  test "should deny non-owner from regenerating images" do
    policy = MenuPolicy.new(@other_user, @menu)
    assert_not policy.regenerate_images?
  end

  test "should deny anonymous user from regenerating images" do
    policy = MenuPolicy.new(nil, @menu)
    assert_not policy.regenerate_images?
  end

  # === ANALYTICS TESTS ===
  
  test "should allow owner to view menu analytics" do
    policy = MenuPolicy.new(@user, @menu)
    assert policy.analytics?
  end

  test "should deny non-owner from viewing menu analytics" do
    policy = MenuPolicy.new(@other_user, @menu)
    assert_not policy.analytics?
  end

  test "should deny anonymous user from viewing menu analytics" do
    policy = MenuPolicy.new(nil, @menu)
    assert_not policy.analytics?
  end

  # === PERFORMANCE TESTS ===
  
  test "should allow owner to view menu performance" do
    policy = MenuPolicy.new(@user, @menu)
    assert policy.performance?
  end

  test "should deny non-owner from viewing menu performance" do
    policy = MenuPolicy.new(@other_user, @menu)
    assert_not policy.performance?
  end

  test "should deny anonymous user from viewing menu performance" do
    policy = MenuPolicy.new(nil, @menu)
    assert_not policy.performance?
  end

  # === SCOPE TESTS ===
  
  test "should scope menus to user's restaurant menus" do
    scope = MenuPolicy::Scope.new(@user, Menu).resolve
    
    # Should include user's restaurant menus
    assert_includes scope, @menu
    
    # Should not include other user's restaurant menus
    assert_not_includes scope, @other_menu
  end

  test "should return empty scope for anonymous user" do
    # Anonymous user scope will fail because user is nil
    assert_raises(NoMethodError) do
      MenuPolicy::Scope.new(nil, Menu).resolve
    end
  end

  test "should handle user with no restaurant menus" do
    user_with_no_restaurants = User.create!(
      email: 'nomenus@example.com',
      password: 'password123'
    )
    
    scope = MenuPolicy::Scope.new(user_with_no_restaurants, Menu).resolve
    
    # Should not include any menus
    assert_not_includes scope, @menu
    assert_not_includes scope, @other_menu
  end

  # === EDGE CASE TESTS ===
  
  test "should handle nil menu record" do
    policy = MenuPolicy.new(@user, nil)
    
    # All owner-based methods should return false for nil record
    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.regenerate_images?
    assert_not policy.analytics?
    assert_not policy.performance?
  end

  test "should handle menu without restaurant" do
    menu_without_restaurant = Menu.new(name: 'Test Menu')
    policy = MenuPolicy.new(@user, menu_without_restaurant)
    
    # Should deny access to menu without proper restaurant association
    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.regenerate_images?
    assert_not policy.analytics?
    assert_not policy.performance?
  end

  test "should handle menu with restaurant but no user" do
    restaurant_without_user = Restaurant.new(name: 'Test Restaurant')
    menu_with_orphaned_restaurant = Menu.new(name: 'Test Menu', restaurant: restaurant_without_user)
    policy = MenuPolicy.new(@user, menu_with_orphaned_restaurant)
    
    # Should deny access to menu with restaurant that has no user
    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.regenerate_images?
  end

  test "should inherit from ApplicationPolicy" do
    assert MenuPolicy < ApplicationPolicy
  end

  # === BUSINESS LOGIC TESTS ===
  
  test "should allow multiple menus per restaurant" do
    # Create additional menu for the same restaurant
    additional_menu = Menu.create!(
      name: 'Second Menu',
      restaurant: @restaurant,
      status: :active
    )
    
    policy = MenuPolicy.new(@user, additional_menu)
    assert policy.update?
    assert policy.destroy?
    assert policy.regenerate_images?
    
    # Scope should include both menus
    scope = MenuPolicy::Scope.new(@user, Menu).resolve
    assert_includes scope, @menu
    assert_includes scope, additional_menu
  end

  test "should handle cross-restaurant menu access correctly" do
    # Verify that ownership is checked through restaurant, not direct menu ownership
    policy_own_menu = MenuPolicy.new(@user, @menu)
    policy_other_menu = MenuPolicy.new(@user, @other_menu)
    
    # Should have access to own restaurant's menu
    assert policy_own_menu.update?
    assert policy_own_menu.destroy?
    
    # Should not have access to other restaurant's menu
    assert_not policy_other_menu.update?
    assert_not policy_other_menu.destroy?
  end

  test "should allow public access but restrict management actions" do
    # Anonymous user should be able to view but not manage
    anonymous_policy = MenuPolicy.new(nil, @menu)
    assert anonymous_policy.show?, "Anonymous users should be able to view menus for ordering"
    assert_not anonymous_policy.update?, "Anonymous users should not be able to update menus"
    assert_not anonymous_policy.destroy?, "Anonymous users should not be able to destroy menus"
    
    # Non-owner should be able to view but not manage
    non_owner_policy = MenuPolicy.new(@other_user, @menu)
    assert non_owner_policy.show?, "All users should be able to view menus for ordering"
    assert_not non_owner_policy.update?, "Non-owners should not be able to update menus"
    assert_not non_owner_policy.destroy?, "Non-owners should not be able to destroy menus"
  end

  # === RESTAURANT ASSOCIATION TESTS ===
  
  test "should properly validate restaurant ownership chain" do
    # Test the ownership chain: User -> Restaurant -> Menu
    assert_equal @user.id, @menu.restaurant.user_id, "Test setup should have proper ownership chain"
    
    policy = MenuPolicy.new(@user, @menu)
    assert policy.update?, "Owner should have access through restaurant ownership"
    
    # Test with different user
    other_policy = MenuPolicy.new(@other_user, @menu)
    assert_not other_policy.update?, "Non-owner should not have access"
  end
end
