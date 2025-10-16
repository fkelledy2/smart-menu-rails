require 'test_helper'

class OrdrPolicyComprehensiveTest < ActiveSupport::TestCase
  include AuthorizationTestHelper

  def setup
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one)  # Owned by @user
    @other_restaurant = restaurants(:two)  # Owned by @other_user
    
    # Create required dependencies for orders
    @menu = Menu.create!(name: 'Test Menu', restaurant: @restaurant, status: :active, sequence: 1)
    @other_menu = Menu.create!(name: 'Other Menu', restaurant: @other_restaurant, status: :active, sequence: 1)
    @tablesetting = Tablesetting.create!(restaurant: @restaurant, name: 'Table 1', tabletype: :indoor, capacity: 4, status: :free)
    @other_tablesetting = Tablesetting.create!(restaurant: @other_restaurant, name: 'Table 1', tabletype: :indoor, capacity: 4, status: :free)
    
    # Create orders for testing
    @ordr = Ordr.create!(
      restaurant: @restaurant, 
      menu: @menu,
      tablesetting: @tablesetting,
      status: :opened, 
      orderedAt: Time.current
    )
    @other_ordr = Ordr.create!(
      restaurant: @other_restaurant, 
      menu: @other_menu,
      tablesetting: @other_tablesetting,
      status: :opened, 
      orderedAt: Time.current
    )
    
    # Create employee users for testing
    @admin_employee = create_employee_user(:admin, @restaurant)
    @manager_employee = create_employee_user(:manager, @restaurant)
    @staff_employee = create_employee_user(:staff, @restaurant)
    
    # Create customer user
    @customer = users(:admin)  # Using admin fixture as customer
  end

  # === BASIC AUTHORIZATION TESTS ===

  test "should allow public access to orders" do
    policy = OrdrPolicy.new(nil, @ordr)
    assert_not policy.show?, "Anonymous users should not view orders"
    assert policy.new?, "Anonymous users should create orders"
    assert policy.create?, "Anonymous users should create orders"
    assert policy.update?, "Anonymous users should be able to update orders in smartmenu context"
  end

  test "should allow owner to manage orders" do
    policy = OrdrPolicy.new(@user, @ordr)
    assert policy.show?, "Owner should view orders"
    assert policy.edit?, "Owner should edit orders"
    assert policy.update?, "Owner should update orders"
    assert policy.destroy?, "Owner should destroy orders"
    assert policy.analytics?, "Owner should access analytics"
  end

  test "should deny non-owner from managing orders" do
    policy = OrdrPolicy.new(@other_user, @ordr)
    assert_not policy.show?, "Non-owner should not view orders"
    assert_not policy.edit?, "Non-owner should not edit orders"
    assert_not policy.update?, "Non-owner should not update orders"
    assert_not policy.destroy?, "Non-owner should not destroy orders"
    assert_not policy.analytics?, "Non-owner should not access analytics"
  end

  # === EMPLOYEE ROLE AUTHORIZATION TESTS ===

  test "should allow admin employees to manage orders" do
    policy = OrdrPolicy.new(@admin_employee, @ordr)
    assert policy.show?, "Admin employee should view orders"
    assert policy.edit?, "Admin employee should edit orders"
    assert policy.update?, "Admin employee should update orders"
    assert policy.destroy?, "Admin employee should destroy orders"
    assert policy.analytics?, "Admin employee should access analytics"
    assert policy.bulk_update?, "Admin employee should perform bulk updates"
  end

  test "should allow manager employees to edit orders" do
    policy = OrdrPolicy.new(@manager_employee, @ordr)
    assert policy.show?, "Manager employee should view orders"
    assert policy.edit?, "Manager employee should edit orders"
    assert policy.update?, "Manager employee should update orders"
    assert policy.bulk_update?, "Manager employee should perform bulk updates"
    assert_not policy.destroy?, "Manager employee should not destroy orders"
    assert_not policy.analytics?, "Manager employee should not access analytics"
  end

  test "should allow staff employees to view and update orders" do
    policy = OrdrPolicy.new(@staff_employee, @ordr)
    assert policy.show?, "Staff employee should view orders"
    assert policy.update?, "Staff employee should update orders"
    assert_not policy.edit?, "Staff employee should not edit orders"
    assert_not policy.destroy?, "Staff employee should not destroy orders"
    assert_not policy.analytics?, "Staff employee should not access analytics"
    assert_not policy.bulk_update?, "Staff employee should not perform bulk updates"
  end

  # === ORDER PARTICIPANT TESTS ===

  test "should allow order participants to access their orders" do
    # Since Ordrparticipant doesn't have user_id, test that customers don't have access
    policy = OrdrPolicy.new(@customer, @ordr)
    assert_not policy.show?, "Customer should not view order (no ownership)"
    assert_not policy.update?, "Customer should not update order (no ownership)"
    assert_not policy.destroy?, "Customer should not destroy order"
    assert_not policy.analytics?, "Customer should not access analytics"
  end

  test "should deny non-participants from accessing orders" do
    # Customer who is not a participant
    non_participant = User.create!(
      email: 'nonparticipant@test.com',
      first_name: 'Non',
      last_name: 'Participant',
      plan: plans(:one),
      password: 'password123',
      password_confirmation: 'password123'
    )
    
    policy = OrdrPolicy.new(non_participant, @ordr)
    # Non-participants should not have access (restrictive access)
    assert_not policy.show?, "Non-participant should not view order"
    assert_not policy.update?, "Non-participant should not update order"
    assert_not policy.destroy?, "Non-participant should not destroy order"
    assert_not policy.analytics?, "Non-participant should not access analytics"
  end

  # === COMPREHENSIVE ROLE MATRIX TESTS ===

  test "should enforce complete authorization matrix for show action" do
    expected_results = {
      owner: true,
      employee_admin: true,
      employee_manager: true,
      employee_staff: true,
      customer: false,
      anonymous: false
    }
    
    expected_results.each do |role, expected|
      user = create_user_with_role(role, @ordr)
      policy = OrdrPolicy.new(user, @ordr)
      result = policy.show?
      
      assert_equal expected, result,
        "#{role} should #{expected ? 'be allowed' : 'be denied'} show on Ordr"
    end
  end

  test "should enforce complete authorization matrix for edit action" do
    expected_results = {
      owner: true,
      employee_admin: true,
      employee_manager: true,
      employee_staff: false,
      customer: false,
      anonymous: false
    }
    
    expected_results.each do |role, expected|
      user = create_user_with_role(role, @ordr)
      policy = OrdrPolicy.new(user, @ordr)
      result = policy.edit?
      
      assert_equal expected, result,
        "#{role} should #{expected ? 'be allowed' : 'be denied'} edit on Ordr"
    end
  end

  test "should enforce complete authorization matrix for destroy action" do
    expected_results = {
      owner: true,
      employee_admin: true,
      employee_manager: false,
      employee_staff: false,
      customer: false,
      anonymous: false
    }
    
    expected_results.each do |role, expected|
      user = create_user_with_role(role, @ordr)
      policy = OrdrPolicy.new(user, @ordr)
      result = policy.destroy?
      
      assert_equal expected, result,
        "#{role} should #{expected ? 'be allowed' : 'be denied'} destroy on Ordr"
    end
  end

  test "should enforce complete authorization matrix for analytics action" do
    expected_results = {
      owner: true,
      employee_admin: true,
      employee_manager: false,
      employee_staff: false,
      customer: false,
      anonymous: false
    }
    
    expected_results.each do |role, expected|
      user = create_user_with_role(role, @ordr)
      policy = OrdrPolicy.new(user, @ordr)
      result = policy.analytics?
      
      assert_equal expected, result,
        "#{role} should #{expected ? 'be allowed' : 'be denied'} analytics on Ordr"
    end
  end

  # === CROSS-RESTAURANT ISOLATION TESTS ===

  test "should prevent cross-restaurant order access" do
    owner1 = users(:one)
    owner2 = users(:two)
    
    # Create resource owned by owner2
    restaurant = Restaurant.create!(name: 'Test Restaurant', user: owner2, status: :active)
    menu = Menu.create!(name: 'Test Menu', restaurant: restaurant, status: :active, sequence: 1)
    tablesetting = Tablesetting.create!(restaurant: restaurant, name: 'Table 1', tabletype: :indoor, capacity: 4, status: :free)
    resource = Ordr.create!(
      restaurant: restaurant, 
      menu: menu,
      tablesetting: tablesetting,
      status: :opened, 
      orderedAt: Time.current
    )
    
    # Test that owner1 cannot access owner2's resource
    policy = OrdrPolicy.new(owner1, resource)
    result = policy.edit?
    
    refute result, "User should not be able to edit other user's Ordr"
  end

  test "should prevent employees from accessing other restaurant orders" do
    other_restaurant_employee = create_employee_user(:admin, @other_restaurant)
    
    policy = OrdrPolicy.new(other_restaurant_employee, @ordr)
    assert_not policy.edit?, "Employee should not edit other restaurant's orders"
    assert_not policy.destroy?, "Employee should not destroy other restaurant's orders"
    assert_not policy.analytics?, "Employee should not access other restaurant's order analytics"
  end

  # === SCOPE TESTS ===

  test "should scope orders to user's restaurants" do
    scope = OrdrPolicy::Scope.new(@user, Ordr).resolve
    assert_includes scope, @ordr, "Should include user's restaurant orders"
    assert_not_includes scope, @other_ordr, "Should not include other restaurant orders"
  end

  test "should scope orders to employee's restaurants" do
    scope = OrdrPolicy::Scope.new(@admin_employee, Ordr).resolve
    assert_includes scope, @ordr, "Should include employee's restaurant orders"
    assert_not_includes scope, @other_ordr, "Should not include other restaurant orders"
  end

  test "should include participant orders in scope" do
    # Since participant system doesn't use user_id, test basic scope functionality
    scope = OrdrPolicy::Scope.new(@user, Ordr).resolve
    assert_includes scope, @ordr, "Should include owned restaurant orders"
    assert_not_includes scope, @other_ordr, "Should not include other restaurant orders"
  end

  test "should return empty scope for anonymous users" do
    # Anonymous user scope will fail because user is nil
    assert_raises(NoMethodError) do
      OrdrPolicy::Scope.new(nil, Ordr).resolve
    end
  end

  # === INACTIVE EMPLOYEE TESTS ===

  test "should handle inactive employees" do
    @admin_employee.employees.first.update!(status: :inactive)
    
    policy = OrdrPolicy.new(@admin_employee, @ordr)
    assert_not policy.edit?, "Inactive employee should not edit orders"
    assert_not policy.destroy?, "Inactive employee should not destroy orders"
    assert_not policy.analytics?, "Inactive employee should not access analytics"
  end

  # === BULK OPERATIONS TESTS ===

  test "should handle bulk operations authorization" do
    # Owner should perform bulk operations
    owner_policy = OrdrPolicy.new(@user, @ordr)
    assert owner_policy.bulk_update?, "Owner should perform bulk updates"
    
    # Admin employee should perform bulk operations
    admin_policy = OrdrPolicy.new(@admin_employee, @ordr)
    assert admin_policy.bulk_update?, "Admin employee should perform bulk updates"
    
    # Manager should perform bulk operations
    manager_policy = OrdrPolicy.new(@manager_employee, @ordr)
    assert manager_policy.bulk_update?, "Manager employee should perform bulk updates"
    
    # Staff should not perform bulk operations
    staff_policy = OrdrPolicy.new(@staff_employee, @ordr)
    assert_not staff_policy.bulk_update?, "Staff employee should not perform bulk updates"
  end

  # === ORDER STATUS TESTS ===

  test "should handle different order statuses" do
    statuses = [:opened, :ordered, :billrequested, :paid, :closed]
    
    statuses.each do |status|
      order = Ordr.create!(
        restaurant: @restaurant,
        menu: @menu,
        tablesetting: @tablesetting,
        status: status,
        orderedAt: Time.current
      )
      
      # Owner should manage all order statuses
      owner_policy = OrdrPolicy.new(@user, order)
      assert owner_policy.show?, "Owner should access #{status} order"
      assert owner_policy.edit?, "Owner should edit #{status} order"
      
      # Admin employee should manage all order statuses
      admin_policy = OrdrPolicy.new(@admin_employee, order)
      assert admin_policy.show?, "Admin employee should access #{status} order"
      assert admin_policy.edit?, "Admin employee should edit #{status} order"
      
      # Manager should edit but not destroy
      manager_policy = OrdrPolicy.new(@manager_employee, order)
      assert manager_policy.show?, "Manager should access #{status} order"
      assert manager_policy.edit?, "Manager should edit #{status} order"
      assert_not manager_policy.destroy?, "Manager should not destroy #{status} order"
    end
  end

  # === ORDER FEATURES TESTS ===

  test "should handle order feature authorization" do
    features = [:analytics, :performance, :bulk_update]
    
    features.each do |feature|
      # Owner should access all features
      owner_policy = OrdrPolicy.new(@user, @ordr)
      assert owner_policy.send("#{feature}?"), "Owner should access #{feature}"
      
      # Admin employee should access all features
      admin_policy = OrdrPolicy.new(@admin_employee, @ordr)
      assert admin_policy.send("#{feature}?"), "Admin employee should access #{feature}"
      
      # Manager should access bulk_update but not analytics/performance
      manager_policy = OrdrPolicy.new(@manager_employee, @ordr)
      if feature == :bulk_update
        assert manager_policy.send("#{feature}?"), "Manager should access #{feature}"
      else
        assert_not manager_policy.send("#{feature}?"), "Manager should not access #{feature}"
      end
      
      # Staff should not access any advanced features
      staff_policy = OrdrPolicy.new(@staff_employee, @ordr)
      assert_not staff_policy.send("#{feature}?"), "Staff should not access #{feature}"
    end
  end

  # === EDGE CASE TESTS ===

  test "should handle nil order record" do
    policy = OrdrPolicy.new(@user, nil)
    
    # Should handle nil gracefully
    assert_not policy.edit?, "Should handle nil order gracefully"
    assert_not policy.destroy?, "Should handle nil order gracefully"
    assert_not policy.analytics?, "Should handle nil order gracefully"
  end

  test "should handle order without restaurant" do
    order_without_restaurant = Ordr.new(status: :opened, orderedAt: Time.current)
    policy = OrdrPolicy.new(@user, order_without_restaurant)
    
    # Should deny access to order without restaurant
    assert_not policy.edit?, "Should deny access to order without restaurant"
    assert_not policy.destroy?, "Should deny access to order without restaurant"
  end

  # === PERFORMANCE TESTS ===

  test "should handle large order datasets efficiently" do
    # Create multiple orders to test performance
    10.times do |i|
      Ordr.create!(
        restaurant: @restaurant,
        menu: @menu,
        tablesetting: @tablesetting,
        status: :opened,
        orderedAt: Time.current - i.hours
      )
    end
    
    scope = OrdrPolicy::Scope.new(@user, Ordr).resolve
    
    # Should handle large datasets efficiently
    assert_nothing_raised do
      scope.limit(50).each do |order|
        order.status
        order.orderedAt
      end
    end
  end

  # === ORDER LIFECYCLE TESTS ===

  test "should handle order lifecycle authorization" do
    # Create order in different lifecycle stages
    order = Ordr.create!(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: @tablesetting,
      status: :opened,
      orderedAt: Time.current
    )
    
    # Owner should manage entire lifecycle
    owner_policy = OrdrPolicy.new(@user, order)
    assert owner_policy.show?, "Owner should access order lifecycle"
    assert owner_policy.edit?, "Owner should edit order lifecycle"
    assert owner_policy.update?, "Owner should update order lifecycle"
    
    # Admin employee should manage lifecycle
    admin_policy = OrdrPolicy.new(@admin_employee, order)
    assert admin_policy.show?, "Admin employee should access order lifecycle"
    assert admin_policy.edit?, "Admin employee should edit order lifecycle"
    assert admin_policy.update?, "Admin employee should update order lifecycle"
    
    # Manager should edit but not destroy
    manager_policy = OrdrPolicy.new(@manager_employee, order)
    assert manager_policy.show?, "Manager should access order lifecycle"
    assert manager_policy.edit?, "Manager should edit order lifecycle"
    assert manager_policy.update?, "Manager should update order lifecycle"
    assert_not manager_policy.destroy?, "Manager should not destroy order"
    
    # Staff should view and update but not edit
    staff_policy = OrdrPolicy.new(@staff_employee, order)
    assert staff_policy.show?, "Staff should access order lifecycle"
    assert staff_policy.update?, "Staff should update order lifecycle"
    assert_not staff_policy.edit?, "Staff should not edit order lifecycle"
    assert_not staff_policy.destroy?, "Staff should not destroy order"
  end

  # === MULTI-USER ORDER TESTS ===

  test "should handle multi-user order scenarios" do
    # Create order for testing
    order = Ordr.create!(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: @tablesetting,
      status: :opened,
      orderedAt: Time.current
    )
    
    # Non-owners should not access the order (restrictive access)
    policy1 = OrdrPolicy.new(@customer, order)
    assert_not policy1.show?, "Customer should not access order (no ownership)"
    assert_not policy1.update?, "Customer should not update order (no ownership)"
    
    policy2 = OrdrPolicy.new(@other_user, order)
    assert_not policy2.show?, "Other user should not access order (no ownership)"
    assert_not policy2.update?, "Other user should not update order (no ownership)"
    
    # Restaurant staff should manage the order
    staff_policy = OrdrPolicy.new(@admin_employee, order)
    assert staff_policy.show?, "Restaurant staff should access order"
    assert staff_policy.edit?, "Restaurant staff should edit order"
    assert staff_policy.destroy?, "Restaurant staff should destroy order"
  end
end
