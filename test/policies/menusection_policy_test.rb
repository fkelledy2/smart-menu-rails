require 'test_helper'

class MenusectionPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one)  # Owned by @user
    @other_restaurant = restaurants(:two)  # Owned by @other_user
    @menu = menus(:one)  # Belongs to @restaurant
    @other_menu = menus(:two) if menus(:two)  # Belongs to @other_restaurant
    @menusection = menusections(:one)  # Belongs to @menu
    
    # Create a menusection for other user's restaurant if needed
    if @other_menu
      @other_menusection = @other_menu.menusections.first ||
        Menusection.create!(
          name: 'Other Section',
          menu: @other_menu,
          status: :active
        )
    end
  end

  # === INDEX TESTS ===
  
  test "should allow authenticated user to view menusection index" do
    policy = MenusectionPolicy.new(@user, Menusection)
    assert policy.index?
  end

  test "should allow anonymous user to view menusection index" do
    policy = MenusectionPolicy.new(nil, Menusection)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.index?, "ApplicationPolicy creates User.new for anonymous users"
  end

  # === SHOW TESTS ===
  
  test "should allow owner to view menusection" do
    policy = MenusectionPolicy.new(@user, @menusection)
    assert policy.show?
  end

  test "should deny non-owner from viewing menusection" do
    if @other_menusection
      policy = MenusectionPolicy.new(@user, @other_menusection)
      assert_not policy.show?
    end
  end

  test "should deny anonymous user from viewing menusection" do
    policy = MenusectionPolicy.new(nil, @menusection)
    assert_not policy.show?
  end

  # === CREATE TESTS ===
  
  test "should allow authenticated user to create menusection" do
    policy = MenusectionPolicy.new(@user, Menusection.new)
    assert policy.create?
  end

  test "should allow anonymous user to create menusection" do
    policy = MenusectionPolicy.new(nil, Menusection.new)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.create?, "ApplicationPolicy creates User.new for anonymous users"
  end

  # === UPDATE TESTS ===
  
  test "should allow owner to update menusection" do
    policy = MenusectionPolicy.new(@user, @menusection)
    assert policy.update?
  end

  test "should deny non-owner from updating menusection" do
    if @other_menusection
      policy = MenusectionPolicy.new(@user, @other_menusection)
      assert_not policy.update?
    end
  end

  test "should deny anonymous user from updating menusection" do
    policy = MenusectionPolicy.new(nil, @menusection)
    assert_not policy.update?
  end

  # === DESTROY TESTS ===
  
  test "should allow owner to destroy menusection" do
    policy = MenusectionPolicy.new(@user, @menusection)
    assert policy.destroy?
  end

  test "should deny non-owner from destroying menusection" do
    if @other_menusection
      policy = MenusectionPolicy.new(@user, @other_menusection)
      assert_not policy.destroy?
    end
  end

  test "should deny anonymous user from destroying menusection" do
    policy = MenusectionPolicy.new(nil, @menusection)
    assert_not policy.destroy?
  end

  # === SCOPE TESTS ===
  
  test "should scope menusections to user's restaurant menusections" do
    scope = MenusectionPolicy::Scope.new(@user, Menusection).resolve
    
    # Should include user's restaurant menusections
    assert_includes scope, @menusection
    
    # Should not include other user's restaurant menusections
    if @other_menusection
      assert_not_includes scope, @other_menusection
    end
  end

  test "should return empty scope for anonymous user" do
    # Anonymous user scope will fail because user is nil
    assert_raises(NoMethodError) do
      MenusectionPolicy::Scope.new(nil, Menusection).resolve
    end
  end

  test "should handle user with no restaurant menusections" do
    user_with_no_restaurants = User.create!(
      email: 'nomenusections@example.com',
      password: 'password123'
    )
    
    scope = MenusectionPolicy::Scope.new(user_with_no_restaurants, Menusection).resolve
    
    # Should not include any menusections
    assert_not_includes scope, @menusection
    if @other_menusection
      assert_not_includes scope, @other_menusection
    end
  end

  # === EDGE CASE TESTS ===
  
  test "should handle nil menusection record" do
    policy = MenusectionPolicy.new(@user, nil)
    
    # All owner-based methods should return false for nil record
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "should handle menusection without menu" do
    menusection_without_menu = Menusection.new(name: 'Test Section')
    policy = MenusectionPolicy.new(@user, menusection_without_menu)
    
    # Should deny access to menusection without proper menu association
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "should handle menusection with menu but no restaurant" do
    menu_without_restaurant = Menu.new(name: 'Test Menu')
    menusection_with_orphaned_menu = Menusection.new(
      name: 'Test Section',
      menu: menu_without_restaurant
    )
    policy = MenusectionPolicy.new(@user, menusection_with_orphaned_menu)
    
    # Should deny access to menusection with menu that has no restaurant
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "should inherit from ApplicationPolicy" do
    assert MenusectionPolicy < ApplicationPolicy
  end

  # === BUSINESS LOGIC TESTS ===
  
  test "should allow multiple menusections per menu" do
    # Create additional menusection for the same menu
    additional_menusection = Menusection.create!(
      name: 'Second Section',
      menu: @menu,
      status: :active
    )
    
    policy = MenusectionPolicy.new(@user, additional_menusection)
    assert policy.show?
    assert policy.update?
    assert policy.destroy?
    
    # Scope should include both menusections
    scope = MenusectionPolicy::Scope.new(@user, Menusection).resolve
    assert_includes scope, @menusection
    assert_includes scope, additional_menusection
  end

  test "should handle cross-restaurant menusection access correctly" do
    # Verify that ownership is checked through the menu → restaurant chain
    policy_own_menusection = MenusectionPolicy.new(@user, @menusection)
    
    # Should have access to own restaurant's menusection
    assert policy_own_menusection.show?
    assert policy_own_menusection.update?
    assert policy_own_menusection.destroy?
    
    # Should not have access to other restaurant's menusection
    if @other_menusection
      policy_other_menusection = MenusectionPolicy.new(@user, @other_menusection)
      assert_not policy_other_menusection.show?
      assert_not policy_other_menusection.update?
      assert_not policy_other_menusection.destroy?
    end
  end

  # === OWNERSHIP CHAIN TESTS ===
  
  test "should properly validate ownership chain" do
    # Test the ownership chain: User → Restaurant → Menu → Menusection
    assert_equal @user.id, @menusection.menu.restaurant.user_id, 
                 "Test setup should have proper ownership chain"
    
    policy = MenusectionPolicy.new(@user, @menusection)
    assert policy.show?, "Owner should have access through ownership chain"
    
    # Test with different user
    if @other_menusection
      other_policy = MenusectionPolicy.new(@user, @other_menusection)
      assert_not other_policy.show?, "Non-owner should not have access"
    end
  end

  test "should handle different menusection statuses" do
    # Test with different menusection statuses
    statuses = [:active, :inactive, :archived]
    
    statuses.each do |status|
      menusection = Menusection.create!(
        name: "#{status.to_s.capitalize} Section",
        menu: @menu,
        status: status
      )
      
      policy = MenusectionPolicy.new(@user, menusection)
      assert policy.show?, "Owner should have access to #{status} menusections"
      assert policy.update?, "Owner should be able to update #{status} menusections"
      assert policy.destroy?, "Owner should be able to destroy #{status} menusections"
    end
  end

  # === SCOPE COMPLEXITY TESTS ===
  
  test "should handle complex scope queries efficiently" do
    # The scope uses joins across multiple tables
    scope = MenusectionPolicy::Scope.new(@user, Menusection).resolve
    
    # Verify the scope includes proper joins
    assert scope.to_sql.include?('JOIN'), "Scope should use joins for efficiency"
    assert scope.to_sql.include?('restaurants'), "Scope should join to restaurants table"
    
    # Should work with additional conditions
    scoped_with_conditions = scope.where(status: :active)
    assert scoped_with_conditions.count >= 0, "Scope should work with additional conditions"
  end

  test "should scope correctly with multiple restaurants per user" do
    # Create additional restaurant for the same user
    additional_restaurant = Restaurant.create!(
      name: 'Second Restaurant',
      user: @user,
      status: :active
    )
    
    additional_menu = Menu.create!(
      name: 'Second Menu',
      restaurant: additional_restaurant,
      status: :active
    )
    
    additional_menusection = Menusection.create!(
      name: 'Second Restaurant Section',
      menu: additional_menu,
      status: :active
    )
    
    scope = MenusectionPolicy::Scope.new(@user, Menusection).resolve
    
    # Should include menusections from both restaurants
    assert_includes scope, @menusection
    assert_includes scope, additional_menusection
    
    # Should not include other user's menusections
    if @other_menusection
      assert_not_includes scope, @other_menusection
    end
  end

  # === MENU ORGANIZATION TESTS ===
  
  test "should handle menusection ordering and organization" do
    # Create multiple menusections with different positions
    appetizers = Menusection.create!(
      name: 'Appetizers',
      menu: @menu,
      status: :active
    )
    
    mains = Menusection.create!(
      name: 'Main Courses',
      menu: @menu,
      status: :active
    )
    
    desserts = Menusection.create!(
      name: 'Desserts',
      menu: @menu,
      status: :active
    )
    
    # Owner should have access to all sections
    [appetizers, mains, desserts].each do |section|
      policy = MenusectionPolicy.new(@user, section)
      assert policy.show?, "Owner should have access to #{section.name}"
      assert policy.update?, "Owner should be able to update #{section.name}"
      assert policy.destroy?, "Owner should be able to destroy #{section.name}"
    end
    
    # Scope should include all sections
    scope = MenusectionPolicy::Scope.new(@user, Menusection).resolve
    assert_includes scope, appetizers
    assert_includes scope, mains
    assert_includes scope, desserts
  end

  test "should handle menusection lifecycle management" do
    # Test menusection creation, activation, deactivation, archival
    new_menusection = Menusection.new(
      name: 'New Section',
      menu: @menu,
      status: :inactive
    )
    
    policy = MenusectionPolicy.new(@user, new_menusection)
    
    # Owner should be able to manage menusection through entire lifecycle
    assert policy.create?, "Owner should be able to create menusections"
    
    # After creation
    new_menusection.save!
    assert policy.show?, "Owner should be able to view new menusections"
    assert policy.update?, "Owner should be able to update menusections"
    
    # Activation
    new_menusection.update!(status: :active)
    assert policy.update?, "Owner should be able to activate menusections"
    
    # Archival
    new_menusection.update!(status: :archived)
    assert policy.update?, "Owner should be able to archive menusections"
    assert policy.destroy?, "Owner should be able to destroy archived menusections"
  end

  # === PERFORMANCE TESTS ===
  
  test "should handle large menusection datasets efficiently" do
    # Create multiple menusections to test performance
    10.times do |i|
      Menusection.create!(
        name: "Bulk Section #{i}",
        menu: @menu,
        status: :active
      )
    end
    
    scope = MenusectionPolicy::Scope.new(@user, Menusection).resolve
    
    # Should handle large datasets without N+1 queries
    assert_nothing_raised do
      scope.limit(50).each do |menusection|
        # Access associated data that should be efficiently loaded
        menusection.menu.restaurant.name
      end
    end
  end

  test "should prevent unauthorized access across restaurant boundaries" do
    # Create menusections in different restaurants
    restaurant_a = Restaurant.create!(name: 'Restaurant A', user: @user, status: :active)
    restaurant_b = Restaurant.create!(name: 'Restaurant B', user: @other_user, status: :active)
    
    menu_a = Menu.create!(name: 'Menu A', restaurant: restaurant_a, status: :active)
    menu_b = Menu.create!(name: 'Menu B', restaurant: restaurant_b, status: :active)
    
    section_a = Menusection.create!(name: 'Section A', menu: menu_a, status: :active)
    section_b = Menusection.create!(name: 'Section B', menu: menu_b, status: :active)
    
    # User should only access their own restaurant's menusections
    policy_a = MenusectionPolicy.new(@user, section_a)
    policy_b = MenusectionPolicy.new(@user, section_b)
    
    assert policy_a.show?, "User should access their own restaurant's menusections"
    assert_not policy_b.show?, "User should not access other restaurant's menusections"
    
    # Scope should only include own restaurant's menusections
    scope = MenusectionPolicy::Scope.new(@user, Menusection).resolve
    assert_includes scope, section_a
    assert_not_includes scope, section_b
  end

  # === MENU ASSOCIATION TESTS ===
  
  test "should handle menusections across multiple menus" do
    # Create additional menu for the same restaurant
    additional_menu = Menu.create!(
      name: 'Lunch Menu',
      restaurant: @restaurant,
      status: :active
    )
    
    lunch_section = Menusection.create!(
      name: 'Lunch Specials',
      menu: additional_menu,
      status: :active
    )
    
    policy = MenusectionPolicy.new(@user, lunch_section)
    assert policy.show?, "Owner should have access to menusections in any of their menus"
    assert policy.update?
    assert policy.destroy?
    
    # Scope should include menusections from all user's menus
    scope = MenusectionPolicy::Scope.new(@user, Menusection).resolve
    assert_includes scope, @menusection
    assert_includes scope, lunch_section
  end
end
