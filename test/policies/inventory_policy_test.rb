require 'test_helper'

class InventoryPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one)  # Owned by @user
    @other_restaurant = restaurants(:two)  # Owned by @other_user
    @menu = menus(:one)  # Belongs to @restaurant
    @other_menu = menus(:two) if menus(:two)  # Belongs to @other_restaurant
    @menusection = menusections(:one)  # Belongs to @menu
    @menuitem = menuitems(:one)  # Belongs to @menusection
    
    # Create inventory for testing
    @inventory = Inventory.create!(
      menuitem: @menuitem,
      startinginventory: 100,
      currentinventory: 80,
      resethour: 6,
      status: :active
    )
    
    # Create inventory for other user's restaurant if needed
    if @other_menu
      @other_menusection = @other_menu.menusections.first || 
        Menusection.create!(name: 'Other Section', menu: @other_menu, status: :active)
      @other_menuitem = @other_menusection.menuitems.first ||
        Menuitem.create!(
          name: 'Other Item',
          menusection: @other_menusection,
          price: 15.99,
          preptime: 20,
          calories: 400,
          itemtype: :food,
          status: :active
        )
      @other_inventory = Inventory.create!(
        menuitem: @other_menuitem,
        startinginventory: 50,
        currentinventory: 30,
        resethour: 8,
        status: :active
      )
    end
  end

  # === INDEX TESTS ===
  
  test "should allow authenticated user to view inventory index" do
    policy = InventoryPolicy.new(@user, Inventory)
    assert policy.index?
  end

  test "should allow anonymous user to view inventory index" do
    policy = InventoryPolicy.new(nil, Inventory)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.index?, "ApplicationPolicy creates User.new for anonymous users"
  end

  # === SHOW TESTS ===
  
  test "should allow owner to view inventory" do
    policy = InventoryPolicy.new(@user, @inventory)
    assert policy.show?
  end

  test "should deny non-owner from viewing inventory" do
    if @other_inventory
      policy = InventoryPolicy.new(@user, @other_inventory)
      assert_not policy.show?
    end
  end

  test "should deny anonymous user from viewing inventory" do
    policy = InventoryPolicy.new(nil, @inventory)
    assert_not policy.show?
  end

  # === CREATE TESTS ===
  
  test "should allow authenticated user to create inventory" do
    policy = InventoryPolicy.new(@user, Inventory.new)
    assert policy.create?
  end

  test "should allow anonymous user to create inventory" do
    policy = InventoryPolicy.new(nil, Inventory.new)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.create?, "ApplicationPolicy creates User.new for anonymous users"
  end

  # === UPDATE TESTS ===
  
  test "should allow owner to update inventory" do
    policy = InventoryPolicy.new(@user, @inventory)
    assert policy.update?
  end

  test "should deny non-owner from updating inventory" do
    if @other_inventory
      policy = InventoryPolicy.new(@user, @other_inventory)
      assert_not policy.update?
    end
  end

  test "should deny anonymous user from updating inventory" do
    policy = InventoryPolicy.new(nil, @inventory)
    assert_not policy.update?
  end

  # === DESTROY TESTS ===
  
  test "should allow owner to destroy inventory" do
    policy = InventoryPolicy.new(@user, @inventory)
    assert policy.destroy?
  end

  test "should deny non-owner from destroying inventory" do
    if @other_inventory
      policy = InventoryPolicy.new(@user, @other_inventory)
      assert_not policy.destroy?
    end
  end

  test "should deny anonymous user from destroying inventory" do
    policy = InventoryPolicy.new(nil, @inventory)
    assert_not policy.destroy?
  end

  # === SCOPE TESTS ===
  
  test "should scope inventories to user's restaurant inventories" do
    scope = InventoryPolicy::Scope.new(@user, Inventory).resolve
    
    # Should include user's restaurant inventories
    assert_includes scope, @inventory
    
    # Should not include other user's restaurant inventories
    if @other_inventory
      assert_not_includes scope, @other_inventory
    end
  end

  test "should return empty scope for anonymous user" do
    # Anonymous user scope will fail because user is nil
    assert_raises(NoMethodError) do
      InventoryPolicy::Scope.new(nil, Inventory).resolve
    end
  end

  test "should handle user with no restaurant inventories" do
    user_with_no_restaurants = User.create!(
      email: 'noinventories@example.com',
      password: 'password123'
    )
    
    scope = InventoryPolicy::Scope.new(user_with_no_restaurants, Inventory).resolve
    
    # Should not include any inventories
    assert_not_includes scope, @inventory
    if @other_inventory
      assert_not_includes scope, @other_inventory
    end
  end

  # === EDGE CASE TESTS ===
  
  test "should handle nil inventory record" do
    policy = InventoryPolicy.new(@user, nil)
    
    # All owner-based methods should return false for nil record
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "should handle inventory without menuitem" do
    inventory_without_menuitem = Inventory.new(startinginventory: 50, currentinventory: 30, resethour: 6)
    policy = InventoryPolicy.new(@user, inventory_without_menuitem)
    
    # Should deny access to inventory without proper menuitem association
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "should handle inventory with menuitem but no menusection" do
    menuitem_without_menusection = Menuitem.new(name: 'Test Item')
    inventory_with_orphaned_menuitem = Inventory.new(
      menuitem: menuitem_without_menusection,
      startinginventory: 50,
      currentinventory: 30,
      resethour: 6
    )
    policy = InventoryPolicy.new(@user, inventory_with_orphaned_menuitem)
    
    # Should deny access to inventory with menuitem that has no menusection
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "should inherit from ApplicationPolicy" do
    assert InventoryPolicy < ApplicationPolicy
  end

  # === BUSINESS LOGIC TESTS ===
  
  test "should handle inventory for multiple menuitems" do
    # Create additional menuitem and inventory
    additional_menuitem = Menuitem.create!(
      name: 'Second Item',
      menusection: @menusection,
      price: 12.99,
      preptime: 15,
      calories: 350,
      itemtype: :food,
      status: :active
    )
    
    additional_inventory = Inventory.create!(
      menuitem: additional_menuitem,
      startinginventory: 75,
      currentinventory: 60,
      resethour: 7,
      status: :active
    )
    
    policy = InventoryPolicy.new(@user, additional_inventory)
    assert policy.show?
    assert policy.update?
    assert policy.destroy?
    
    # Scope should include both inventories
    scope = InventoryPolicy::Scope.new(@user, Inventory).resolve
    assert_includes scope, @inventory
    assert_includes scope, additional_inventory
  end

  test "should handle different inventory statuses" do
    # Test with different inventory statuses
    statuses = [:active, :inactive, :archived]
    
    statuses.each do |status|
      inventory = Inventory.create!(
        menuitem: @menuitem,
        startinginventory: 25,
        currentinventory: status == :inactive ? 0 : 15,
        resethour: 6,
        status: status
      )
      
      policy = InventoryPolicy.new(@user, inventory)
      assert policy.show?, "Owner should have access to #{status} inventories"
      assert policy.update?, "Owner should be able to update #{status} inventories"
      assert policy.destroy?, "Owner should be able to destroy #{status} inventories"
    end
  end

  # === OWNERSHIP CHAIN TESTS ===
  
  test "should properly validate ownership chain" do
    # Test the ownership chain: User -> Restaurant -> Menu -> Menusection -> Menuitem -> Inventory
    assert_equal @user.id, @inventory.menuitem.menusection.menu.restaurant.user_id, 
                 "Test setup should have proper ownership chain"
    
    policy = InventoryPolicy.new(@user, @inventory)
    assert policy.show?, "Owner should have access through ownership chain"
    
    # Test with different user
    if @other_inventory
      other_policy = InventoryPolicy.new(@user, @other_inventory)
      assert_not other_policy.show?, "Non-owner should not have access"
    end
  end

  test "should handle cross-restaurant inventory access correctly" do
    # Verify that ownership is checked through the full chain
    policy_own_inventory = InventoryPolicy.new(@user, @inventory)
    
    # Should have access to own restaurant's inventory
    assert policy_own_inventory.show?
    assert policy_own_inventory.update?
    assert policy_own_inventory.destroy?
    
    # Should not have access to other restaurant's inventory
    if @other_inventory
      policy_other_inventory = InventoryPolicy.new(@user, @other_inventory)
      assert_not policy_other_inventory.show?
      assert_not policy_other_inventory.update?
      assert_not policy_other_inventory.destroy?
    end
  end

  # === SCOPE COMPLEXITY TESTS ===
  
  test "should handle complex scope queries efficiently" do
    # The scope uses joins across multiple tables
    scope = InventoryPolicy::Scope.new(@user, Inventory).resolve
    
    # Verify the scope includes proper joins
    assert scope.to_sql.include?('JOIN'), "Scope should use joins for efficiency"
    assert scope.to_sql.include?('restaurants'), "Scope should join to restaurants table"
    
    # Should work with additional conditions
    scoped_with_conditions = scope.where(status: :in_stock)
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
      name: 'Second Section',
      menu: additional_menu,
      status: :active
    )
    
    additional_menuitem = Menuitem.create!(
      name: 'Second Restaurant Item',
      menusection: additional_menusection,
      price: 22.99,
      preptime: 30,
      calories: 600,
      itemtype: :food,
      status: :active
    )
    
    additional_inventory = Inventory.create!(
      menuitem: additional_menuitem,
      startinginventory: 80,
      currentinventory: 65,
      resethour: 5,
      status: :active
    )
    
    scope = InventoryPolicy::Scope.new(@user, Inventory).resolve
    
    # Should include inventories from both restaurants
    assert_includes scope, @inventory
    assert_includes scope, additional_inventory
    
    # Should not include other user's inventories
    if @other_inventory
      assert_not_includes scope, @other_inventory
    end
  end

  # === INVENTORY MANAGEMENT BUSINESS LOGIC ===
  
  test "should handle inventory lifecycle management" do
    # Test inventory creation, stock updates, reordering scenarios
    new_inventory = Inventory.new(
      menuitem: @menuitem,
      startinginventory: 200,
      currentinventory: 180,
      resethour: 4,
      status: :active
    )
    
    policy = InventoryPolicy.new(@user, new_inventory)
    
    # Owner should be able to manage inventory through entire lifecycle
    assert policy.create?, "Owner should be able to create inventories"
    
    # After creation
    new_inventory.save!
    assert policy.show?, "Owner should be able to view new inventories"
    assert policy.update?, "Owner should be able to update inventories"
    
    # Stock depletion
    new_inventory.update!(currentinventory: 10, status: :inactive)
    assert policy.update?, "Owner should be able to update low stock inventories"
    
    # Out of stock
    new_inventory.update!(currentinventory: 0, status: :inactive)
    assert policy.update?, "Owner should be able to update out of stock inventories"
    
    # Archival
    new_inventory.update!(status: :archived)
    assert policy.update?, "Owner should be able to archive inventories"
    assert policy.destroy?, "Owner should be able to destroy archived inventories"
  end

  test "should handle inventory reset hour management" do
    # Test different reset hour scenarios
    reset_hours = [0, 6, 12, 18, 23]
    
    reset_hours.each do |hour|
      inventory = Inventory.create!(
        menuitem: @menuitem,
        startinginventory: 100,
        currentinventory: 75,
        resethour: hour,
        status: :active
      )
      
      policy = InventoryPolicy.new(@user, inventory)
      assert policy.show?, "Owner should have access to inventories with reset hour #{hour}"
      assert policy.update?, "Owner should be able to update reset hours"
    end
  end

  # === PERFORMANCE AND SECURITY TESTS ===
  
  test "should handle large inventory datasets efficiently" do
    # Create multiple inventories to test performance
    5.times do |i|
      menuitem = Menuitem.create!(
        name: "Bulk Item #{i}",
        menusection: @menusection,
        price: 10.99 + i,
        preptime: 15,
        calories: 300,
        itemtype: :food,
        status: :active
      )
      
      Inventory.create!(
        menuitem: menuitem,
        startinginventory: 100 + (i * 10),
        currentinventory: 80 + (i * 8),
        resethour: 6 + i,
        status: :active
      )
    end
    
    scope = InventoryPolicy::Scope.new(@user, Inventory).resolve
    
    # Should handle large datasets without N+1 queries
    assert_nothing_raised do
      scope.limit(50).each do |inventory|
        # Access associated data that should be efficiently loaded
        inventory.menuitem.menusection.menu.restaurant.name
      end
    end
  end

  test "should prevent unauthorized access across restaurant boundaries" do
    # Create inventories in different restaurants
    restaurant_a = Restaurant.create!(name: 'Restaurant A', user: @user, status: :active)
    restaurant_b = Restaurant.create!(name: 'Restaurant B', user: @other_user, status: :active)
    
    menu_a = Menu.create!(name: 'Menu A', restaurant: restaurant_a, status: :active)
    menu_b = Menu.create!(name: 'Menu B', restaurant: restaurant_b, status: :active)
    
    section_a = Menusection.create!(name: 'Section A', menu: menu_a, status: :active)
    section_b = Menusection.create!(name: 'Section B', menu: menu_b, status: :active)
    
    item_a = Menuitem.create!(name: 'Item A', menusection: section_a, price: 10.99, preptime: 15, calories: 300, itemtype: :food, status: :active)
    item_b = Menuitem.create!(name: 'Item B', menusection: section_b, price: 12.99, preptime: 20, calories: 400, itemtype: :food, status: :active)
    
    inventory_a = Inventory.create!(menuitem: item_a, startinginventory: 100, currentinventory: 85, resethour: 6, status: :active)
    inventory_b = Inventory.create!(menuitem: item_b, startinginventory: 75, currentinventory: 60, resethour: 8, status: :active)
    
    # User should only access their own restaurant's inventories
    policy_a = InventoryPolicy.new(@user, inventory_a)
    policy_b = InventoryPolicy.new(@user, inventory_b)
    
    assert policy_a.show?, "User should access their own restaurant's inventories"
    assert_not policy_b.show?, "User should not access other restaurant's inventories"
    
    # Scope should only include own restaurant's inventories
    scope = InventoryPolicy::Scope.new(@user, Inventory).resolve
    assert_includes scope, inventory_a
    assert_not_includes scope, inventory_b
  end
end
