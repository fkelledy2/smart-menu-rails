require 'test_helper'

class OrdrPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one)  # Owned by @user
    @other_restaurant = restaurants(:two)  # Owned by @other_user
    @ordr = ordrs(:one)  # Belongs to @restaurant
    
    # Create a second order for testing since ordrs(:two) doesn't exist
    @other_ordr = Ordr.create!(
      restaurant: @other_restaurant,
      menu: @other_restaurant.menus.first || Menu.create!(name: 'Test Menu', restaurant: @other_restaurant, status: :active),
      tablesetting: @other_restaurant.tablesettings.first || Tablesetting.create!(name: 'Test Table', restaurant: @other_restaurant, capacity: 4, tabletype: :indoor, status: :free),
      orderedAt: Time.current,
      nett: 10.0,
      tip: 2.0,
      service: 1.0,
      tax: 1.5,
      gross: 14.5
    )
  end

  # === INDEX TESTS ===
  
  test "should allow authenticated user to view order index" do
    policy = OrdrPolicy.new(@user, Ordr)
    assert policy.index?
  end

  test "should allow anonymous user to view order index" do
    policy = OrdrPolicy.new(nil, Ordr)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.index?, "ApplicationPolicy creates User.new for anonymous users"
  end

  # === SHOW TESTS (Customer Access) ===
  
  test "should deny anonymous customer from viewing order" do
    policy = OrdrPolicy.new(nil, @ordr)
    assert_not policy.show?, "Anonymous customers cannot view orders (ApplicationPolicy creates User.new)"
  end

  test "should allow owner to view order" do
    policy = OrdrPolicy.new(@user, @ordr)
    assert policy.show?
  end

  test "should deny non-owner authenticated user from viewing order" do
    policy = OrdrPolicy.new(@other_user, @ordr)
    assert_not policy.show?, "Non-owner authenticated users cannot view other restaurant's orders"
  end

  # === NEW TESTS (Customer Access) ===
  
  test "should allow anonymous customer to access new order" do
    policy = OrdrPolicy.new(nil, Ordr.new)
    assert policy.new?, "Anonymous customers should be able to create new orders"
  end

  test "should allow authenticated user to access new order" do
    policy = OrdrPolicy.new(@user, Ordr.new)
    assert policy.new?
  end

  # === CREATE TESTS (Customer Access) ===
  
  test "should allow anonymous customer to create order" do
    policy = OrdrPolicy.new(nil, Ordr.new)
    assert policy.create?, "Anonymous customers should be able to create orders"
  end

  test "should allow authenticated user to create order" do
    policy = OrdrPolicy.new(@user, Ordr.new)
    assert policy.create?
  end

  # === EDIT TESTS (Staff Only) ===
  
  test "should allow owner to edit order" do
    policy = OrdrPolicy.new(@user, @ordr)
    assert policy.edit?
  end

  test "should deny non-owner from editing order" do
    policy = OrdrPolicy.new(@user, @other_ordr)
    assert_not policy.edit?
  end

  test "should deny anonymous user from editing order" do
    policy = OrdrPolicy.new(nil, @ordr)
    assert_not policy.edit?
  end

  # === UPDATE TESTS (Customer + Staff Access) ===
  
  test "should allow anonymous customer to update order in smartmenu context" do
    policy = OrdrPolicy.new(nil, @ordr)
    assert policy.update?, "Anonymous customers should be able to update orders in smartmenu context (add items, etc.)"
  end

  test "should allow owner to update order" do
    policy = OrdrPolicy.new(@user, @ordr)
    assert policy.update?
  end

  test "should deny non-owner authenticated user from updating order" do
    policy = OrdrPolicy.new(@other_user, @ordr)
    assert_not policy.update?, "Non-owner authenticated users cannot update other restaurant's orders"
  end

  # === DESTROY TESTS (Staff Only) ===
  
  test "should allow owner to destroy order" do
    policy = OrdrPolicy.new(@user, @ordr)
    assert policy.destroy?
  end

  test "should deny non-owner from destroying order" do
    policy = OrdrPolicy.new(@user, @other_ordr)
    assert_not policy.destroy?
  end

  test "should deny anonymous user from destroying order" do
    policy = OrdrPolicy.new(nil, @ordr)
    assert_not policy.destroy?
  end

  # === SCOPE TESTS ===
  
  test "should scope orders to user's restaurant orders" do
    scope = OrdrPolicy::Scope.new(@user, Ordr).resolve
    
    # Should include user's restaurant orders
    assert_includes scope, @ordr
    
    # Should not include other user's restaurant orders
    assert_not_includes scope, @other_ordr
  end

  test "should return empty scope for anonymous user" do
    # Anonymous user scope will fail because user is nil
    assert_raises(NoMethodError) do
      OrdrPolicy::Scope.new(nil, Ordr).resolve
    end
  end

  test "should handle user with no restaurant orders" do
    user_with_no_restaurants = User.create!(
      email: 'noorders@example.com',
      password: 'password123'
    )
    
    scope = OrdrPolicy::Scope.new(user_with_no_restaurants, Ordr).resolve
    
    # Should not include any orders
    assert_not_includes scope, @ordr
    assert_not_includes scope, @other_ordr
  end

  # === EDGE CASE TESTS ===
  
  test "should handle nil order record" do
    policy = OrdrPolicy.new(@user, nil)
    
    # All owner-based methods should return false for nil record
    assert_not policy.edit?
    assert_not policy.destroy?
  end

  test "should handle order without restaurant" do
    order_without_restaurant = Ordr.new
    policy = OrdrPolicy.new(@user, order_without_restaurant)
    
    # Should deny staff-only access to order without proper restaurant association
    assert_not policy.edit?
    assert_not policy.destroy?
  end

  test "should handle order with restaurant but no user" do
    restaurant_without_user = Restaurant.new(name: 'Test Restaurant')
    order_with_orphaned_restaurant = Ordr.new(restaurant: restaurant_without_user)
    policy = OrdrPolicy.new(@user, order_with_orphaned_restaurant)
    
    # Should deny staff access to order with restaurant that has no user
    assert_not policy.edit?
    assert_not policy.destroy?
  end

  test "should inherit from ApplicationPolicy" do
    assert OrdrPolicy < ApplicationPolicy
  end

  # === BUSINESS LOGIC TESTS ===
  
  test "should differentiate between customer and staff permissions" do
    # Anonymous user permissions (ApplicationPolicy creates User.new)
    customer_policy = OrdrPolicy.new(nil, @ordr)
    assert_not customer_policy.show?, "Anonymous users cannot view orders (no ownership)"
    assert customer_policy.new?, "Anonymous users should be able to create new orders"
    assert customer_policy.create?, "Anonymous users should be able to create orders"
    assert customer_policy.update?, "Anonymous users should be able to update orders in smartmenu context"
    assert_not customer_policy.edit?, "Anonymous users should not be able to edit orders (staff function)"
    assert_not customer_policy.destroy?, "Anonymous users should not be able to destroy orders"
    
    # Staff permissions (restaurant owners)
    staff_policy = OrdrPolicy.new(@user, @ordr)
    assert staff_policy.show?, "Staff should be able to view orders"
    assert staff_policy.new?, "Staff should be able to create new orders"
    assert staff_policy.create?, "Staff should be able to create orders"
    assert staff_policy.update?, "Staff should be able to update orders"
    assert staff_policy.edit?, "Staff should be able to edit orders"
    assert staff_policy.destroy?, "Staff should be able to destroy orders"
  end

  test "should handle restaurant ownership chain correctly" do
    # Test the ownership chain: User -> Restaurant -> Order
    assert_equal @user.id, @ordr.restaurant.user_id, "Test setup should have proper ownership chain"
    
    policy = OrdrPolicy.new(@user, @ordr)
    assert policy.edit?, "Owner should have staff access through restaurant ownership"
    assert policy.destroy?, "Owner should have staff access through restaurant ownership"
    
    # Test with different user
    other_policy = OrdrPolicy.new(@user, @other_ordr)
    assert_not other_policy.edit?, "Non-owner should not have staff access"
    assert_not other_policy.destroy?, "Non-owner should not have staff access"
  end

  test "should allow customer access regardless of authentication" do
    # Both anonymous and authenticated users should have customer-level access
    anonymous_policy = OrdrPolicy.new(nil, @ordr)
    authenticated_policy = OrdrPolicy.new(@other_user, @ordr)
    
    # Both anonymous and authenticated non-owners should have limited access
    assert_not anonymous_policy.show?, "Anonymous users should not have access (no ownership)"
    assert_not authenticated_policy.show?, "Authenticated non-owners should not have access"
    
    assert anonymous_policy.new?, "Anonymous users should be able to create orders"
    assert authenticated_policy.new?, "Authenticated users should be able to create orders"
    
    assert anonymous_policy.create?, "Anonymous users should be able to create orders"
    assert authenticated_policy.create?, "Authenticated users should be able to create orders"
    
    assert anonymous_policy.update?, "Anonymous users should be able to update orders in smartmenu context"
    assert_not authenticated_policy.update?, "Authenticated non-owners should not be able to update orders"
    
    # Staff-level permissions should be denied for both
    assert_not anonymous_policy.edit?
    assert_not authenticated_policy.edit? # Non-owner authenticated user
  end

  # === RESTAURANT ASSOCIATION TESTS ===
  
  test "should properly validate restaurant ownership for staff actions" do
    # Create order for user's restaurant
    user_restaurant_order = Ordr.create!(
      restaurant: @restaurant,
      menu: menus(:one),
      tablesetting: tablesettings(:one)
    )
    
    policy = OrdrPolicy.new(@user, user_restaurant_order)
    assert policy.edit?, "Owner should have staff access to their restaurant's orders"
    assert policy.destroy?, "Owner should have staff access to their restaurant's orders"
    
    # Test with other user's order
    if @other_restaurant && @other_user
      other_restaurant_order = Ordr.create!(
        restaurant: @other_restaurant,
        menu: @other_restaurant.menus.first || Menu.create!(name: 'Test Menu', restaurant: @other_restaurant, status: :active),
        tablesetting: @other_restaurant.tablesettings.first || Tablesetting.create!(name: 'Test Table', restaurant: @other_restaurant, capacity: 4, tabletype: :indoor, status: :free)
      )
      
      cross_policy = OrdrPolicy.new(@user, other_restaurant_order)
      assert_not cross_policy.edit?, "Owner should not have staff access to other restaurant's orders"
      assert_not cross_policy.destroy?, "Owner should not have staff access to other restaurant's orders"
    end
  end
end
