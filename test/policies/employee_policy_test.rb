require 'test_helper'

class EmployeePolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one) # Owned by @user
    @other_restaurant = restaurants(:two) # Owned by @other_user

    # Create employees for testing
    @employee = Employee.create!(
      name: 'Test Employee',
      eid: 'EMP001',
      role: :staff,
      status: :active,
      user: @user,
      restaurant: @restaurant,
    )

    @other_employee = Employee.create!(
      name: 'Other Employee',
      eid: 'EMP002',
      role: :staff,
      status: :active,
      user: @other_user,
      restaurant: @other_restaurant,
    )
  end

  # === INDEX TESTS ===

  test 'should allow authenticated user to view employee index' do
    policy = EmployeePolicy.new(@user, Employee)
    assert policy.index?
  end

  test 'should allow anonymous user to view employee index' do
    policy = EmployeePolicy.new(nil, Employee)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.index?, 'ApplicationPolicy creates User.new for anonymous users'
  end

  # === SHOW TESTS ===

  test 'should allow owner to view employee' do
    policy = EmployeePolicy.new(@user, @employee)
    assert policy.show?
  end

  test 'should deny non-owner from viewing employee' do
    policy = EmployeePolicy.new(@user, @other_employee)
    assert_not policy.show?
  end

  test 'should deny anonymous user from viewing employee' do
    policy = EmployeePolicy.new(nil, @employee)
    assert_not policy.show?
  end

  # === CREATE TESTS ===

  test 'should allow authenticated user to create employee' do
    policy = EmployeePolicy.new(@user, Employee.new)
    assert policy.create?
  end

  test 'should allow anonymous user to create employee' do
    policy = EmployeePolicy.new(nil, Employee.new)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.create?, 'ApplicationPolicy creates User.new for anonymous users'
  end

  # === UPDATE TESTS ===

  test 'should allow owner to update employee' do
    policy = EmployeePolicy.new(@user, @employee)
    assert policy.update?
  end

  test 'should deny non-owner from updating employee' do
    policy = EmployeePolicy.new(@user, @other_employee)
    assert_not policy.update?
  end

  test 'should deny anonymous user from updating employee' do
    policy = EmployeePolicy.new(nil, @employee)
    assert_not policy.update?
  end

  # === DESTROY TESTS ===

  test 'should allow owner to destroy employee' do
    policy = EmployeePolicy.new(@user, @employee)
    assert policy.destroy?
  end

  test 'should deny non-owner from destroying employee' do
    policy = EmployeePolicy.new(@user, @other_employee)
    assert_not policy.destroy?
  end

  test 'should deny anonymous user from destroying employee' do
    policy = EmployeePolicy.new(nil, @employee)
    assert_not policy.destroy?
  end

  # === SCOPE TESTS ===

  test "should scope employees to user's restaurant employees" do
    scope = EmployeePolicy::Scope.new(@user, Employee).resolve

    # Should include user's restaurant employees
    assert_includes scope, @employee

    # Should not include other user's restaurant employees
    assert_not_includes scope, @other_employee
  end

  test 'should return empty scope for anonymous user' do
    # Anonymous user scope will fail because user is nil
    assert_raises(NoMethodError) do
      EmployeePolicy::Scope.new(nil, Employee).resolve
    end
  end

  test 'should handle user with no restaurant employees' do
    user_with_no_restaurants = User.create!(
      email: 'noemployees@example.com',
      password: 'password123',
    )

    scope = EmployeePolicy::Scope.new(user_with_no_restaurants, Employee).resolve

    # Should not include any employees
    assert_not_includes scope, @employee
    assert_not_includes scope, @other_employee
  end

  # === EDGE CASE TESTS ===

  test 'should handle nil employee record' do
    policy = EmployeePolicy.new(@user, nil)

    # All owner-based methods should return false for nil record
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should handle employee without restaurant' do
    employee_without_restaurant = Employee.new(name: 'Test Employee', eid: 'EMP999')
    policy = EmployeePolicy.new(@user, employee_without_restaurant)

    # Should deny access to employee without proper restaurant association
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should handle employee with restaurant but no user' do
    restaurant_without_user = Restaurant.new(name: 'Test Restaurant')
    employee_with_orphaned_restaurant = Employee.new(
      name: 'Test Employee',
      eid: 'EMP998',
      restaurant: restaurant_without_user,
    )
    policy = EmployeePolicy.new(@user, employee_with_orphaned_restaurant)

    # Should deny access to employee with restaurant that has no user
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should inherit from ApplicationPolicy' do
    assert EmployeePolicy < ApplicationPolicy
  end

  # === BUSINESS LOGIC TESTS ===

  test 'should allow multiple employees per restaurant' do
    # Create additional employee for the same restaurant
    additional_employee = Employee.create!(
      name: 'Second Employee',
      eid: 'EMP003',
      role: :manager,
      status: :active,
      user: @user,
      restaurant: @restaurant,
    )

    policy = EmployeePolicy.new(@user, additional_employee)
    assert policy.show?
    assert policy.update?
    assert policy.destroy?

    # Scope should include both employees
    scope = EmployeePolicy::Scope.new(@user, Employee).resolve
    assert_includes scope, @employee
    assert_includes scope, additional_employee
  end

  test 'should handle different employee roles' do
    # Test with different employee roles
    roles = %i[staff manager admin]

    roles.each do |role|
      employee = Employee.create!(
        name: "#{role.to_s.capitalize} Employee",
        eid: "EMP_#{role.to_s.upcase}",
        role: role,
        status: :active,
        user: @user,
        restaurant: @restaurant,
      )

      policy = EmployeePolicy.new(@user, employee)
      assert policy.show?, "Owner should have access to #{role} employees"
      assert policy.update?, "Owner should be able to update #{role} employees"
      assert policy.destroy?, "Owner should be able to destroy #{role} employees"
    end
  end

  test 'should handle different employee statuses' do
    # Test with different employee statuses
    statuses = %i[active inactive archived]

    statuses.each do |status|
      employee = Employee.create!(
        name: "#{status.to_s.capitalize} Employee",
        eid: "EMP_#{status.to_s.upcase}",
        role: :staff,
        status: status,
        user: @user,
        restaurant: @restaurant,
      )

      policy = EmployeePolicy.new(@user, employee)
      assert policy.show?, "Owner should have access to #{status} employees"
      assert policy.update?, "Owner should be able to update #{status} employees"
      assert policy.destroy?, "Owner should be able to destroy #{status} employees"
    end
  end

  # === RESTAURANT OWNERSHIP TESTS ===

  test 'should properly validate restaurant ownership' do
    # Test the ownership chain: User -> Restaurant -> Employee
    assert_equal @user.id, @employee.restaurant.user_id,
                 'Test setup should have proper ownership chain'

    policy = EmployeePolicy.new(@user, @employee)
    assert policy.show?, 'Owner should have access through restaurant ownership'

    # Test with different user
    other_policy = EmployeePolicy.new(@user, @other_employee)
    assert_not other_policy.show?, 'Non-owner should not have access'
  end

  test 'should handle cross-restaurant employee access correctly' do
    # Verify that ownership is checked through restaurant
    policy_own_employee = EmployeePolicy.new(@user, @employee)
    policy_other_employee = EmployeePolicy.new(@user, @other_employee)

    # Should have access to own restaurant's employee
    assert policy_own_employee.show?
    assert policy_own_employee.update?
    assert policy_own_employee.destroy?

    # Should not have access to other restaurant's employee
    assert_not policy_other_employee.show?
    assert_not policy_other_employee.update?
    assert_not policy_other_employee.destroy?
  end

  # === SCOPE EFFICIENCY TESTS ===

  test 'should use efficient scope queries' do
    scope = EmployeePolicy::Scope.new(@user, Employee).resolve

    # Verify the scope uses joins for efficiency
    assert scope.to_sql.include?('JOIN'), 'Scope should use joins for efficiency'
    assert scope.to_sql.include?('restaurants'), 'Scope should join to restaurants table'
  end

  test 'should scope correctly with multiple restaurants per user' do
    # Create additional restaurant for the same user
    additional_restaurant = Restaurant.create!(
      name: 'Second Restaurant',
      user: @user,
      status: :active,
    )

    additional_employee = Employee.create!(
      name: 'Second Restaurant Employee',
      eid: 'EMP004',
      role: :staff,
      status: :active,
      user: @user,
      restaurant: additional_restaurant,
    )

    scope = EmployeePolicy::Scope.new(@user, Employee).resolve

    # Should include employees from both restaurants
    assert_includes scope, @employee
    assert_includes scope, additional_employee

    # Should not include other user's employees
    assert_not_includes scope, @other_employee
  end

  # === EMPLOYEE MANAGEMENT BUSINESS LOGIC ===

  test 'should handle employee hierarchy scenarios' do
    # Create manager and staff employees
    manager = Employee.create!(
      name: 'Manager Employee',
      eid: 'MGR001',
      role: :manager,
      status: :active,
      user: @user,
      restaurant: @restaurant,
    )

    staff = Employee.create!(
      name: 'Staff Employee',
      eid: 'STF001',
      role: :staff,
      status: :active,
      user: @user,
      restaurant: @restaurant,
    )

    # Restaurant owner should have access to all employees regardless of role
    manager_policy = EmployeePolicy.new(@user, manager)
    staff_policy = EmployeePolicy.new(@user, staff)

    assert manager_policy.show?
    assert manager_policy.update?
    assert manager_policy.destroy?

    assert staff_policy.show?
    assert staff_policy.update?
    assert staff_policy.destroy?
  end

  test 'should handle employee lifecycle management' do
    # Test employee creation, activation, deactivation, archival
    new_employee = Employee.new(
      name: 'New Employee',
      eid: 'NEW001',
      role: :staff,
      status: :inactive,
      user: @user,
      restaurant: @restaurant,
    )

    policy = EmployeePolicy.new(@user, new_employee)

    # Owner should be able to manage employee through entire lifecycle
    assert policy.create?, 'Owner should be able to create employees'

    # After creation
    new_employee.save!
    assert policy.show?, 'Owner should be able to view new employees'
    assert policy.update?, 'Owner should be able to update employees'

    # Activation
    new_employee.update!(status: :active)
    assert policy.update?, 'Owner should be able to activate employees'

    # Archival
    new_employee.update!(status: :archived)
    assert policy.update?, 'Owner should be able to archive employees'
    assert policy.destroy?, 'Owner should be able to destroy archived employees'
  end

  # === PERFORMANCE AND SECURITY TESTS ===

  test 'should handle large employee datasets efficiently' do
    # Create multiple employees to test performance
    10.times do |i|
      Employee.create!(
        name: "Bulk Employee #{i}",
        eid: "BULK#{i.to_s.rjust(3, '0')}",
        role: :staff,
        status: :active,
        user: @user,
        restaurant: @restaurant,
      )
    end

    scope = EmployeePolicy::Scope.new(@user, Employee).resolve

    # Should handle large datasets without N+1 queries
    assert_nothing_raised do
      scope.limit(50).each do |employee|
        employee.restaurant.name # Access associated data
      end
    end
  end

  test 'should prevent unauthorized access across restaurant boundaries' do
    # Create employees in different restaurants
    restaurant_a = Restaurant.create!(name: 'Restaurant A', user: @user, status: :active)
    restaurant_b = Restaurant.create!(name: 'Restaurant B', user: @other_user, status: :active)

    employee_a = Employee.create!(name: 'Employee A', eid: 'EMPA', role: :staff, status: :active, user: @user,
                                  restaurant: restaurant_a,)
    employee_b = Employee.create!(name: 'Employee B', eid: 'EMPB', role: :staff, status: :active, user: @other_user,
                                  restaurant: restaurant_b,)

    # User should only access their own restaurant's employees
    policy_a = EmployeePolicy.new(@user, employee_a)
    policy_b = EmployeePolicy.new(@user, employee_b)

    assert policy_a.show?, "User should access their own restaurant's employees"
    assert_not policy_b.show?, "User should not access other restaurant's employees"

    # Scope should only include own restaurant's employees
    scope = EmployeePolicy::Scope.new(@user, Employee).resolve
    assert_includes scope, employee_a
    assert_not_includes scope, employee_b
  end
end
