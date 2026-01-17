require 'test_helper'

class MenuPolicyComprehensiveTest < ActiveSupport::TestCase
  include AuthorizationTestHelper

  def setup
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one) # Owned by @user
    @other_restaurant = restaurants(:two) # Owned by @other_user
    @menu = menus(:one) # Belongs to @restaurant
    @other_menu = menus(:two) # Belongs to @other_restaurant

    # Create employee users for testing
    @admin_employee = create_employee_user(:admin, @restaurant)
    @manager_employee = create_employee_user(:manager, @restaurant)
    @staff_employee = create_employee_user(:staff, @restaurant)
  end

  # === BASIC AUTHORIZATION TESTS ===

  test 'should allow owner to access menu' do
    policy = MenuPolicy.new(@user, @menu)
    assert policy.show?, 'Owner should access menu'
    assert policy.update?, 'Owner should update menu'
    assert policy.destroy?, 'Owner should destroy menu'
  end

  test 'should allow public access to menu show' do
    policy = MenuPolicy.new(nil, @menu)
    assert policy.show?, 'Anonymous users should view menus'
  end

  test 'should deny non-owner from managing menu' do
    policy = MenuPolicy.new(@other_user, @menu)
    assert_not policy.update?, 'Non-owner should not update menu'
    assert_not policy.destroy?, 'Non-owner should not destroy menu'
    assert_not policy.analytics?, 'Non-owner should not access analytics'
  end

  # === EMPLOYEE ROLE AUTHORIZATION TESTS ===

  test 'should allow admin employees to manage menus' do
    policy = MenuPolicy.new(@admin_employee, @menu)
    assert policy.show?, 'Admin employee should view menu'
    assert policy.update?, 'Admin employee should update menu'
    assert policy.destroy?, 'Admin employee should destroy menu'
    assert policy.analytics?, 'Admin employee should access analytics'
    assert policy.regenerate_images?, 'Admin employee should regenerate images'
  end

  test 'should allow manager employees to update menus' do
    policy = MenuPolicy.new(@manager_employee, @menu)
    assert policy.show?, 'Manager employee should view menu'
    assert policy.update?, 'Manager employee should update menu'
    assert_not policy.destroy?, 'Manager employee should not destroy menu'
    assert_not policy.analytics?, 'Manager employee should not access analytics'
    assert_not policy.regenerate_images?, 'Manager employee should not regenerate images'
  end

  test 'should allow staff employees to view menus only' do
    policy = MenuPolicy.new(@staff_employee, @menu)
    assert policy.show?, 'Staff employee should view menu'
    assert_not policy.update?, 'Staff employee should not update menu'
    assert_not policy.destroy?, 'Staff employee should not destroy menu'
    assert_not policy.analytics?, 'Staff employee should not access analytics'
  end

  test 'should handle menu creation authorization' do
    new_menu = Menu.new(restaurant: @restaurant)

    # Owner should create menus
    owner_policy = MenuPolicy.new(@user, new_menu)
    assert owner_policy.create?, 'Owner should create menus'

    # Admin employee should create menus
    admin_policy = MenuPolicy.new(@admin_employee, new_menu)
    assert admin_policy.create?, 'Admin employee should create menus'

    # Manager and staff should not create menus
    manager_policy = MenuPolicy.new(@manager_employee, new_menu)
    assert_not manager_policy.create?, 'Manager employee should not create menus'

    staff_policy = MenuPolicy.new(@staff_employee, new_menu)
    assert_not staff_policy.create?, 'Staff employee should not create menus'
  end

  # === COMPREHENSIVE ROLE MATRIX TESTS ===

  test 'should enforce complete authorization matrix for show action' do
    expected_results = {
      owner: true,
      employee_admin: true,
      employee_manager: true,
      employee_staff: true,
      customer: true,
      anonymous: true,
    }

    expected_results.each do |role, expected|
      user = create_user_with_role(role, @menu)
      policy = MenuPolicy.new(user, @menu)
      result = policy.show?

      assert_equal expected, result,
                   "#{role} should #{expected ? 'be allowed' : 'be denied'} show on Menu"
    end
  end

  test 'should enforce complete authorization matrix for update action' do
    expected_results = {
      owner: true,
      employee_admin: true,
      employee_manager: true,
      employee_staff: false,
      customer: false,
      anonymous: false,
    }

    expected_results.each do |role, expected|
      user = create_user_with_role(role, @menu)
      policy = MenuPolicy.new(user, @menu)
      result = policy.update?

      assert_equal expected, result,
                   "#{role} should #{expected ? 'be allowed' : 'be denied'} update on Menu"
    end
  end

  test 'should enforce complete authorization matrix for destroy action' do
    expected_results = {
      owner: true,
      employee_admin: true,
      employee_manager: false,
      employee_staff: false,
      customer: false,
      anonymous: false,
    }

    expected_results.each do |role, expected|
      user = create_user_with_role(role, @menu)
      policy = MenuPolicy.new(user, @menu)
      result = policy.destroy?

      assert_equal expected, result,
                   "#{role} should #{expected ? 'be allowed' : 'be denied'} destroy on Menu"
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
      user = create_user_with_role(role, @menu)
      policy = MenuPolicy.new(user, @menu)
      result = policy.analytics?

      assert_equal expected, result,
                   "#{role} should #{expected ? 'be allowed' : 'be denied'} analytics on Menu"
    end
  end

  # === CROSS-RESTAURANT ISOLATION TESTS ===

  test 'should prevent cross-restaurant menu access' do
    owner1 = users(:one)
    owner2 = users(:two)

    # Create resource owned by owner2
    restaurant = Restaurant.create!(name: 'Test Restaurant', user: owner2, status: :active)
    resource = Menu.create!(name: 'Test Menu', restaurant: restaurant, status: :active, sequence: 1)

    # Test that owner1 cannot access owner2's resource
    policy = MenuPolicy.new(owner1, resource)
    result = policy.update?

    assert_not result, "User should not be able to update other user's Menu"
  end

  test 'should prevent employees from accessing other restaurant menus' do
    other_restaurant_employee = create_employee_user(:admin, @other_restaurant)

    policy = MenuPolicy.new(other_restaurant_employee, @menu)
    assert_not policy.update?, "Employee should not update other restaurant's menu"
    assert_not policy.destroy?, "Employee should not destroy other restaurant's menu"
    assert_not policy.analytics?, "Employee should not access other restaurant's menu analytics"
  end

  # === SCOPE TESTS ===

  test "should scope menus to user's restaurants" do
    scope = MenuPolicy::Scope.new(@user, Menu).resolve
    assert_includes scope, @menu, "Should include user's menu"
    assert_not_includes scope, @other_menu, "Should not include other user's menu"
  end

  test "should scope menus to employee's restaurants" do
    scope = MenuPolicy::Scope.new(@admin_employee, Menu).resolve
    assert_includes scope, @menu, "Should include employee's restaurant menu"
    assert_not_includes scope, @other_menu, "Should not include other restaurant's menu"
  end

  test 'should return empty scope for anonymous users' do
    scope = MenuPolicy::Scope.new(nil, Menu).resolve
    assert_equal 0, scope.count
  end

  # === INACTIVE EMPLOYEE TESTS ===

  test 'should handle inactive employees' do
    @admin_employee.employees.first.update!(status: :inactive)

    policy = MenuPolicy.new(@admin_employee, @menu)
    assert_not policy.update?, 'Inactive employee should not update menu'
    assert_not policy.destroy?, 'Inactive employee should not destroy menu'
    assert_not policy.analytics?, 'Inactive employee should not access analytics'
  end

  # === BULK OPERATIONS TESTS ===

  test 'should handle bulk operations authorization' do
    # Owner should perform bulk operations
    owner_policy = MenuPolicy.new(@user, @menu)
    assert owner_policy.bulk_update?, 'Owner should perform bulk updates'

    # Admin employee should perform bulk operations
    admin_policy = MenuPolicy.new(@admin_employee, @menu)
    assert admin_policy.bulk_update?, 'Admin employee should perform bulk updates'

    # Manager and staff should not perform bulk operations
    manager_policy = MenuPolicy.new(@manager_employee, @menu)
    assert_not manager_policy.bulk_update?, 'Manager employee should not perform bulk updates'

    staff_policy = MenuPolicy.new(@staff_employee, @menu)
    assert_not staff_policy.bulk_update?, 'Staff employee should not perform bulk updates'
  end

  # === MENU STATUS TESTS ===

  test 'should handle different menu statuses' do
    statuses = %i[active inactive archived]

    statuses.each do |status|
      menu = Menu.create!(
        name: "#{status.to_s.capitalize} Menu",
        restaurant: @restaurant,
        status: status,
        sequence: 1,
      )

      # Owner should access all menu statuses
      owner_policy = MenuPolicy.new(@user, menu)
      assert owner_policy.show?, "Owner should access #{status} menu"
      assert owner_policy.update?, "Owner should update #{status} menu"

      # Admin employee should access all menu statuses
      admin_policy = MenuPolicy.new(@admin_employee, menu)
      assert admin_policy.show?, "Admin employee should access #{status} menu"
      assert admin_policy.update?, "Admin employee should update #{status} menu"
    end
  end

  # === MENU FEATURES TESTS ===

  test 'should handle menu feature authorization' do
    features = %i[regenerate_images analytics performance]

    features.each do |feature|
      # Owner should access all features
      owner_policy = MenuPolicy.new(@user, @menu)
      assert owner_policy.send("#{feature}?"), "Owner should access #{feature}"

      # Admin employee should access all features
      admin_policy = MenuPolicy.new(@admin_employee, @menu)
      assert admin_policy.send("#{feature}?"), "Admin employee should access #{feature}"

      # Manager should not access advanced features
      manager_policy = MenuPolicy.new(@manager_employee, @menu)
      assert_not manager_policy.send("#{feature}?"), "Manager should not access #{feature}"

      # Staff should not access any features
      staff_policy = MenuPolicy.new(@staff_employee, @menu)
      assert_not staff_policy.send("#{feature}?"), "Staff should not access #{feature}"
    end
  end

  # === EDGE CASE TESTS ===

  test 'should handle nil menu record' do
    policy = MenuPolicy.new(@user, nil)

    # Should handle nil gracefully
    assert_not policy.update?, 'Should handle nil menu gracefully'
    assert_not policy.destroy?, 'Should handle nil menu gracefully'
    assert_not policy.analytics?, 'Should handle nil menu gracefully'
  end

  test 'should handle menu without restaurant' do
    menu_without_restaurant = Menu.new(name: 'Orphan Menu')
    policy = MenuPolicy.new(@user, menu_without_restaurant)

    # Should deny access to menu without restaurant
    assert_not policy.update?, 'Should deny access to menu without restaurant'
    assert_not policy.destroy?, 'Should deny access to menu without restaurant'
  end

  # === PERFORMANCE TESTS ===

  test 'should handle large menu datasets efficiently' do
    # Create multiple menus to test performance
    10.times do |i|
      Menu.create!(
        name: "Bulk Menu #{i}",
        restaurant: @restaurant,
        status: :active,
        sequence: i + 10,
      )
    end

    scope = MenuPolicy::Scope.new(@user, Menu).resolve

    # Should handle large datasets efficiently
    assert_nothing_raised do
      scope.limit(50).each do |menu|
        menu.name
        menu.status
      end
    end
  end

  # === MENU HIERARCHY TESTS ===

  test 'should handle menu hierarchy authorization' do
    # Create menu with sections and items
    menu = Menu.create!(
      name: 'Hierarchy Menu',
      restaurant: @restaurant,
      status: :active,
      sequence: 100,
    )

    # Owner should manage entire hierarchy
    owner_policy = MenuPolicy.new(@user, menu)
    assert owner_policy.show?, 'Owner should access menu hierarchy'
    assert owner_policy.update?, 'Owner should update menu hierarchy'

    # Admin employee should manage hierarchy
    admin_policy = MenuPolicy.new(@admin_employee, menu)
    assert admin_policy.show?, 'Admin employee should access menu hierarchy'
    assert admin_policy.update?, 'Admin employee should update menu hierarchy'

    # Manager should update but not destroy
    manager_policy = MenuPolicy.new(@manager_employee, menu)
    assert manager_policy.show?, 'Manager should access menu hierarchy'
    assert manager_policy.update?, 'Manager should update menu hierarchy'
    assert_not manager_policy.destroy?, 'Manager should not destroy menu hierarchy'
  end
end
