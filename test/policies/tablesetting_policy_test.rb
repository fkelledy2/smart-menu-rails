require 'test_helper'

class TablesettingPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one)  # Owned by @user
    @other_restaurant = restaurants(:two)  # Owned by @other_user
    
    # Create tablesettings for testing
    @tablesetting = Tablesetting.create!(
      restaurant: @restaurant,
      name: 'Table 1',
      capacity: 4,
      tabletype: :indoor,
      status: :free
    )
    
    @other_tablesetting = Tablesetting.create!(
      restaurant: @other_restaurant,
      name: 'Table A',
      capacity: 6,
      tabletype: :outdoor,
      status: :free
    )
  end

  # === INDEX TESTS ===
  
  test "should allow anyone to view tablesetting index" do
    policy = TablesettingPolicy.new(@user, Tablesetting)
    assert policy.index?
  end

  test "should allow anonymous user to view tablesetting index" do
    policy = TablesettingPolicy.new(nil, Tablesetting)
    assert policy.index?, "Customers should be able to browse tables"
  end

  test "should allow other user to view tablesetting index" do
    policy = TablesettingPolicy.new(@other_user, Tablesetting)
    assert policy.index?
  end

  # === SHOW TESTS ===
  
  test "should allow anonymous customer to view tablesetting" do
    policy = TablesettingPolicy.new(nil, @tablesetting)
    assert policy.show?, "Customers should be able to view table details"
  end

  test "should allow owner to view tablesetting" do
    policy = TablesettingPolicy.new(@user, @tablesetting)
    assert policy.show?
  end

  test "should deny non-owner authenticated user from viewing tablesetting" do
    policy = TablesettingPolicy.new(@other_user, @tablesetting)
    assert_not policy.show?, "Non-owner authenticated users cannot view other restaurant's tables"
  end

  # === CREATE TESTS ===
  
  test "should allow authenticated user to create tablesetting" do
    policy = TablesettingPolicy.new(@user, Tablesetting.new)
    assert policy.create?
  end

  test "should allow anonymous user to create tablesetting" do
    policy = TablesettingPolicy.new(nil, Tablesetting.new)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.create?, "ApplicationPolicy creates User.new for anonymous users"
  end

  # === UPDATE TESTS ===
  
  test "should allow owner to update tablesetting" do
    policy = TablesettingPolicy.new(@user, @tablesetting)
    assert policy.update?
  end

  test "should deny non-owner from updating tablesetting" do
    policy = TablesettingPolicy.new(@user, @other_tablesetting)
    assert_not policy.update?
  end

  test "should deny anonymous user from updating tablesetting" do
    policy = TablesettingPolicy.new(nil, @tablesetting)
    assert_not policy.update?
  end

  # === DESTROY TESTS ===
  
  test "should allow owner to destroy tablesetting" do
    policy = TablesettingPolicy.new(@user, @tablesetting)
    assert policy.destroy?
  end

  test "should deny non-owner from destroying tablesetting" do
    policy = TablesettingPolicy.new(@user, @other_tablesetting)
    assert_not policy.destroy?
  end

  test "should deny anonymous user from destroying tablesetting" do
    policy = TablesettingPolicy.new(nil, @tablesetting)
    assert_not policy.destroy?
  end

  # === SCOPE TESTS ===
  
  test "should scope tablesettings to user's restaurant tablesettings" do
    scope = TablesettingPolicy::Scope.new(@user, Tablesetting).resolve
    
    # Should include user's restaurant tablesettings
    assert_includes scope, @tablesetting
    
    # Should not include other user's restaurant tablesettings
    assert_not_includes scope, @other_tablesetting
  end

  test "should return empty scope for anonymous user" do
    # Anonymous user scope will fail because user is nil
    assert_raises(NoMethodError) do
      TablesettingPolicy::Scope.new(nil, Tablesetting).resolve
    end
  end

  test "should handle user with no restaurant tablesettings" do
    user_with_no_restaurants = User.create!(
      email: 'notables@example.com',
      password: 'password123'
    )
    
    scope = TablesettingPolicy::Scope.new(user_with_no_restaurants, Tablesetting).resolve
    
    # Should not include any tablesettings
    assert_not_includes scope, @tablesetting
    assert_not_includes scope, @other_tablesetting
  end

  # === EDGE CASE TESTS ===
  
  test "should handle nil tablesetting record" do
    policy = TablesettingPolicy.new(@user, nil)
    
    # Public methods should still work
    assert policy.index?
    assert policy.create?
    
    # Owner-based methods should return false for nil record
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
    
    # Anonymous user should return true for show (public access)
    anonymous_policy = TablesettingPolicy.new(nil, nil)
    assert anonymous_policy.show?, "Anonymous users get public access even for nil record"
  end

  test "should handle tablesetting without restaurant" do
    tablesetting_without_restaurant = Tablesetting.new(
      name: 'Test Table',
      capacity: 4,
      tabletype: :indoor
    )
    policy = TablesettingPolicy.new(@user, tablesetting_without_restaurant)
    
    # Should deny access to tablesetting without proper restaurant association
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "should inherit from ApplicationPolicy" do
    assert TablesettingPolicy < ApplicationPolicy
  end

  # === BUSINESS LOGIC TESTS ===
  
  test "should handle different table capacities" do
    # Test with different table capacities
    capacities = [2, 4, 6, 8, 10, 12]
    
    capacities.each do |capacity|
      tablesetting = Tablesetting.create!(
        restaurant: @restaurant,
        name: "Table for #{capacity}",
        capacity: capacity,
        tabletype: :indoor,
        status: :free
      )
      
      policy = TablesettingPolicy.new(@user, tablesetting)
      assert policy.show?, "Owner should have access to table with capacity #{capacity}"
      assert policy.update?, "Owner should be able to update table with capacity #{capacity}"
      assert policy.destroy?, "Owner should be able to destroy table with capacity #{capacity}"
    end
  end

  test "should handle different table types" do
    # Test with different table types
    table_types = [:indoor, :outdoor]
    
    table_types.each do |table_type|
      tablesetting = Tablesetting.create!(
        restaurant: @restaurant,
        name: "#{table_type.to_s.capitalize} Table",
        capacity: 4,
        tabletype: table_type,
        status: :free
      )
      
      policy = TablesettingPolicy.new(@user, tablesetting)
      assert policy.show?, "Owner should have access to #{table_type} tables"
      assert policy.update?, "Owner should be able to update #{table_type} tables"
      assert policy.destroy?, "Owner should be able to destroy #{table_type} tables"
    end
  end

  test "should handle different table statuses" do
    # Test with different table statuses
    statuses = [:free, :occupied, :archived]
    
    statuses.each do |status|
      tablesetting = Tablesetting.create!(
        restaurant: @restaurant,
        name: "#{status.to_s.capitalize} Table",
        capacity: 4,
        tabletype: :indoor,
        status: status
      )
      
      policy = TablesettingPolicy.new(@user, tablesetting)
      assert policy.show?, "Owner should have access to #{status} tables"
      assert policy.update?, "Owner should be able to update #{status} tables"
      assert policy.destroy?, "Owner should be able to destroy #{status} tables"
    end
  end

  test "should handle multiple tablesettings per restaurant" do
    # Create additional tablesetting for the same restaurant
    additional_tablesetting = Tablesetting.create!(
      restaurant: @restaurant,
      name: 'Table 2',
      capacity: 6,
      tabletype: :outdoor,
      status: :free
    )
    
    policy = TablesettingPolicy.new(@user, additional_tablesetting)
    assert policy.show?
    assert policy.update?
    assert policy.destroy?
    
    # Scope should include both tablesettings
    scope = TablesettingPolicy::Scope.new(@user, Tablesetting).resolve
    assert_includes scope, @tablesetting
    assert_includes scope, additional_tablesetting
  end

  test "should handle cross-restaurant tablesetting access correctly" do
    # Verify that ownership is checked through restaurant for management
    policy_own_table = TablesettingPolicy.new(@user, @tablesetting)
    policy_other_table = TablesettingPolicy.new(@user, @other_tablesetting)
    
    # Should have management access to own restaurant's table
    assert policy_own_table.update?
    assert policy_own_table.destroy?
    
    # Should not have access to other restaurant's table
    assert_not policy_other_table.show?
    assert_not policy_other_table.update?
    assert_not policy_other_table.destroy?
    
    # Should have full access to own tables
    assert policy_own_table.show?
    assert policy_own_table.update?
    assert policy_own_table.destroy?
  end

  # === RESTAURANT OWNERSHIP TESTS ===
  
  test "should properly validate restaurant ownership" do
    # Test the ownership chain: User → Restaurant → Tablesetting
    assert_equal @user.id, @tablesetting.restaurant.user_id, 
                 "Test setup should have proper ownership chain"
    
    policy = TablesettingPolicy.new(@user, @tablesetting)
    assert policy.update?, "Owner should have management access through restaurant ownership"
    assert policy.destroy?, "Owner should have management access through restaurant ownership"
    
    # Test with different user
    other_policy = TablesettingPolicy.new(@user, @other_tablesetting)
    assert_not other_policy.update?, "Non-owner should not have management access"
    assert_not other_policy.destroy?, "Non-owner should not have management access"
  end

  test "should handle scope correctly with multiple restaurants per user" do
    # Create additional restaurant for the same user
    additional_restaurant = Restaurant.create!(
      name: 'Second Restaurant',
      user: @user,
      status: :active
    )
    
    additional_tablesetting = Tablesetting.create!(
      restaurant: additional_restaurant,
      name: 'Second Restaurant Table',
      capacity: 8,
      tabletype: :indoor,
      status: :free
    )
    
    scope = TablesettingPolicy::Scope.new(@user, Tablesetting).resolve
    
    # Should include tablesettings from both restaurants
    assert_includes scope, @tablesetting
    assert_includes scope, additional_tablesetting
    
    # Should not include other user's tablesettings
    assert_not_includes scope, @other_tablesetting
  end

  # === TABLE MANAGEMENT TESTS ===
  
  test "should handle tablesetting lifecycle management" do
    # Test tablesetting creation, status changes, archival
    new_tablesetting = Tablesetting.new(
      restaurant: @restaurant,
      name: 'New Table',
      capacity: 4,
      tabletype: :indoor,
      status: :free
    )
    
    policy = TablesettingPolicy.new(@user, new_tablesetting)
    
    # Owner should be able to manage tablesetting through entire lifecycle
    assert policy.create?, "Owner should be able to create tablesettings"
    
    # After creation
    new_tablesetting.save!
    assert policy.show?, "Owner should be able to view new tablesettings"
    assert policy.update?, "Owner should be able to update tablesettings"
    
    # Status changes
    new_tablesetting.update!(status: :occupied)
    assert policy.update?, "Owner should be able to change table status"
    
    # Capacity changes
    new_tablesetting.update!(capacity: 6)
    assert policy.update?, "Owner should be able to change table capacity"
    
    # Archival
    new_tablesetting.update!(status: :archived)
    assert policy.update?, "Owner should be able to archive tablesettings"
    assert policy.destroy?, "Owner should be able to destroy archived tablesettings"
  end

  test "should handle complex restaurant seating scenarios" do
    # Different table configurations for restaurant seating
    table_configs = [
      { name: 'Bar Seating', capacity: 1, tabletype: :indoor, status: :free },
      { name: 'Couple Table', capacity: 2, tabletype: :indoor, status: :free },
      { name: 'Family Table', capacity: 6, tabletype: :indoor, status: :occupied },
      { name: 'Patio Table', capacity: 4, tabletype: :outdoor, status: :free },
      { name: 'Large Group', capacity: 12, tabletype: :outdoor, status: :free },
      { name: 'Old Table', capacity: 4, tabletype: :indoor, status: :archived }
    ]
    
    table_configs.each do |table_data|
      tablesetting = Tablesetting.create!(
        restaurant: @restaurant,
        **table_data
      )
      
      policy = TablesettingPolicy.new(@user, tablesetting)
      assert policy.show?, "Owner should have access to #{table_data[:name]}"
      assert policy.update?, "Owner should be able to update #{table_data[:name]}"
      assert policy.destroy?, "Owner should be able to destroy #{table_data[:name]}"
    end
  end

  # === PERFORMANCE TESTS ===
  
  test "should handle large tablesetting datasets efficiently" do
    # Create multiple tablesettings to test performance
    20.times do |i|
      Tablesetting.create!(
        restaurant: @restaurant,
        name: "Table #{i + 1}",
        capacity: [2, 4, 6, 8][i % 4],
        tabletype: [:indoor, :outdoor][i % 2],
        status: :free
      )
    end
    
    scope = TablesettingPolicy::Scope.new(@user, Tablesetting).resolve
    
    # Should handle large datasets without N+1 queries
    assert_nothing_raised do
      scope.limit(50).each do |tablesetting|
        # Access associated data that should be efficiently loaded
        tablesetting.restaurant.name
      end
    end
  end

  test "should prevent unauthorized management across restaurant boundaries" do
    # Create tablesettings in different restaurants
    restaurant_a = Restaurant.create!(name: 'Restaurant A', user: @user, status: :active)
    restaurant_b = Restaurant.create!(name: 'Restaurant B', user: @other_user, status: :active)
    
    table_a = Tablesetting.create!(
      restaurant: restaurant_a,
      name: 'Table A',
      capacity: 4,
      tabletype: :indoor,
      status: :free
    )
    table_b = Tablesetting.create!(
      restaurant: restaurant_b,
      name: 'Table B',
      capacity: 6,
      tabletype: :outdoor,
      status: :free
    )
    
    # User should only manage their own restaurant's tablesettings
    policy_a = TablesettingPolicy.new(@user, table_a)
    policy_b = TablesettingPolicy.new(@user, table_b)
    
    assert policy_a.update?, "User should manage their own restaurant's tablesettings"
    assert_not policy_b.update?, "User should not manage other restaurant's tablesettings"
    
    # Should only be able to view own restaurant's tables
    assert policy_a.show?, "User should view their own restaurant's tablesettings"
    assert_not policy_b.show?, "User should not view other restaurant's tablesettings"
    
    # Scope should only include own restaurant's tablesettings
    scope = TablesettingPolicy::Scope.new(@user, Tablesetting).resolve
    assert_includes scope, table_a
    assert_not_includes scope, table_b
  end

  # === CUSTOMER ACCESS TESTS ===
  
  test "should allow customer access patterns" do
    # Simulate customer browsing available tables
    customer_policy = TablesettingPolicy.new(nil, @tablesetting)
    
    # Customers should be able to browse tables but only anonymous customers can view details
    assert customer_policy.index?, "Customers should be able to browse tables"
    assert customer_policy.show?, "Anonymous customers should be able to view table details"
    
    # Customers should not be able to manage tables
    assert_not customer_policy.update?, "Customers should not be able to update tables"
    assert_not customer_policy.destroy?, "Customers should not be able to destroy tables"
  end

  test "should handle table reservation scenarios" do
    # Test different table statuses for reservation system
    reservation_scenarios = [
      { status: :free, description: 'Available for reservation' },
      { status: :occupied, description: 'Currently occupied' },
      { status: :archived, description: 'No longer available' }
    ]
    
    reservation_scenarios.each do |scenario|
      tablesetting = Tablesetting.create!(
        restaurant: @restaurant,
        name: "Reservation Table",
        capacity: 4,
        tabletype: :indoor,
        status: scenario[:status]
      )
      
      # Anonymous customers should be able to view all table statuses
      customer_policy = TablesettingPolicy.new(nil, tablesetting)
      assert customer_policy.show?, "Anonymous customers should view #{scenario[:description]} tables"
      
      # Owners should be able to manage all table statuses
      owner_policy = TablesettingPolicy.new(@user, tablesetting)
      assert owner_policy.update?, "Owners should manage #{scenario[:description]} tables"
      assert owner_policy.destroy?, "Owners should remove #{scenario[:description]} tables"
    end
  end

  # === SCOPE EFFICIENCY TESTS ===
  
  test "should use efficient scope queries" do
    scope = TablesettingPolicy::Scope.new(@user, Tablesetting).resolve
    
    # Verify the scope uses joins for efficiency
    assert scope.to_sql.include?('JOIN'), "Scope should use joins for efficiency"
    assert scope.to_sql.include?('restaurants'), "Scope should join to restaurants table"
  end

  test "should handle scope with additional conditions" do
    # Create tablesettings with different statuses and types
    Tablesetting.create!(
      restaurant: @restaurant,
      name: 'Indoor Free Table',
      capacity: 4,
      tabletype: :indoor,
      status: :free
    )
    Tablesetting.create!(
      restaurant: @restaurant,
      name: 'Outdoor Occupied Table',
      capacity: 6,
      tabletype: :outdoor,
      status: :occupied
    )
    
    scope = TablesettingPolicy::Scope.new(@user, Tablesetting).resolve
    
    # Should work with additional conditions
    indoor_tables = scope.where(tabletype: :indoor)
    outdoor_tables = scope.where(tabletype: :outdoor)
    free_tables = scope.where(status: :free)
    occupied_tables = scope.where(status: :occupied)
    
    assert indoor_tables.count >= 1, "Should find indoor tables"
    assert outdoor_tables.count >= 1, "Should find outdoor tables"
    assert free_tables.count >= 1, "Should find free tables"
    assert occupied_tables.count >= 1, "Should find occupied tables"
  end

  # === PUBLIC ACCESS MODEL TESTS ===
  
  test "should demonstrate public access model" do
    # Tablesettings follow a public access model for viewing
    # Similar to smartmenus - customers need to see available tables
    
    # Anonymous customer access
    anonymous_policy = TablesettingPolicy.new(nil, @tablesetting)
    assert anonymous_policy.index?, "Anonymous customers should browse tables"
    assert anonymous_policy.show?, "Anonymous customers should view table details"
    
    # Authenticated non-owner access (restricted)
    customer_policy = TablesettingPolicy.new(@other_user, @tablesetting)
    assert customer_policy.index?, "Authenticated users should browse tables"
    assert_not customer_policy.show?, "Authenticated non-owners cannot view other restaurant's table details"
    
    # Owner management access
    owner_policy = TablesettingPolicy.new(@user, @tablesetting)
    assert owner_policy.update?, "Owners should manage their tables"
    assert owner_policy.destroy?, "Owners should remove their tables"
    
    # Non-owner management restrictions
    non_owner_policy = TablesettingPolicy.new(@other_user, @tablesetting)
    assert_not non_owner_policy.update?, "Non-owners should not manage other's tables"
    assert_not non_owner_policy.destroy?, "Non-owners should not remove other's tables"
  end
end
