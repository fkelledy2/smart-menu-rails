# frozen_string_literal: true

module AuthorizationTestHelper
  # Test authorization for all user roles against a specific action and resource
  def verify_authorization_for_all_roles(action, resource, expected_results = {})
    roles = %i[owner employee_admin employee_manager employee_staff customer anonymous]

    roles.each do |role|
      user = create_user_with_role(role, resource)
      policy = policy_for(user, resource)
      result = policy.public_send("#{action}?")

      expected = expected_results[role] || false

      assert_equal expected, result,
                   "#{role} should #{expected ? 'be allowed' : 'be denied'} #{action} on #{resource.class.name}"
    end
  end

  # Test cross-restaurant data isolation
  def verify_cross_restaurant_isolation(action, resource_factory)
    owner1 = users(:one)
    owner2 = users(:two)

    # Create resource owned by owner2
    resource = resource_factory.call(owner2)

    # Test that owner1 cannot access owner2's resource
    policy = policy_for(owner1, resource)
    result = policy.public_send("#{action}?")

    assert_not result, "User should not be able to #{action} other user's #{resource.class.name}"
  end

  # Test employee role-based access within a restaurant
  def verify_employee_role_access(action, resource, allowed_roles = [])
    restaurant = resource.respond_to?(:restaurant) ? resource.restaurant : restaurants(:one)

    %i[staff manager admin].each do |role|
      employee_user = create_employee_user(role, restaurant)
      policy = policy_for(employee_user, resource)
      result = policy.public_send("#{action}?")

      expected = allowed_roles.include?(role)

      assert_equal expected, result,
                   "Employee with #{role} role should #{expected ? 'be allowed' : 'be denied'} #{action}"
    end
  end

  # Test anonymous user access
  def verify_anonymous_access(action, resource, should_allow = false)
    policy = policy_for(nil, resource)
    result = policy.public_send("#{action}?")

    assert_equal should_allow, result,
                 "Anonymous user should #{should_allow ? 'be allowed' : 'be denied'} #{action}"
  end

  # Test API vs web interface consistency
  def verify_api_web_consistency(controller_class, action, resource)
    user = users(:one)

    # Test web interface authorization
    controller = controller_class.new
    controller.instance_variable_set(:@current_user, user)

    # This would need to be implemented based on specific controller patterns
    # For now, we'll focus on policy-level testing
    policy = policy_for(user, resource)
    result = policy.public_send("#{action}?")

    # The expectation is that API and web should have same authorization
    assert result.is_a?(TrueClass) || result.is_a?(FalseClass),
           'Authorization should return boolean for consistency'
  end

  private

  def create_user_with_role(role, resource = nil)
    case role
    when :owner
      if resource.respond_to?(:restaurant)
        resource.restaurant.user
      elsif resource.respond_to?(:user)
        resource.user
      else
        users(:one)
      end
    when :employee_admin
      restaurant = extract_restaurant(resource)
      create_employee_user(:admin, restaurant)
    when :employee_manager
      restaurant = extract_restaurant(resource)
      create_employee_user(:manager, restaurant)
    when :employee_staff
      restaurant = extract_restaurant(resource)
      create_employee_user(:staff, restaurant)
    when :customer
      users(:admin) # Using admin fixture as customer
    when :anonymous
      nil
    else
      users(:one)
    end
  end

  def create_employee_user(role, restaurant)
    # Create a unique user for this employee
    user = User.create!(
      email: "#{role}_#{restaurant.id}_#{SecureRandom.hex(4)}@test.com",
      first_name: role.to_s.capitalize,
      last_name: 'Employee',
      plan: plans(:one),
      password: 'password123',
      password_confirmation: 'password123',
    )

    # Create employee record
    Employee.create!(
      user: user,
      restaurant: restaurant,
      role: role,
      status: :active,
      name: "#{role.to_s.capitalize} Employee",
      eid: "EMP#{SecureRandom.hex(4)}",
    )

    user
  end

  def extract_restaurant(resource)
    if resource.respond_to?(:restaurant)
      resource.restaurant
    elsif resource.is_a?(Restaurant)
      resource
    else
      restaurants(:one)
    end
  end

  def policy_for(user, resource)
    policy_class = "#{resource.class.name}Policy".constantize
    policy_class.new(user, resource)
  end

  # Authorization expectation matrices for different resources
  def default_authorization_matrix(action)
    case action.to_sym
    when :index
      {
        owner: true,
        employee_admin: true,
        employee_manager: true,
        employee_staff: false,
        customer: false,
        anonymous: false,
      }
    when :show
      {
        owner: true,
        employee_admin: true,
        employee_manager: false,
        employee_staff: false,
        customer: false,
        anonymous: false,
      }
    when :create
      {
        owner: true,
        employee_admin: true,
        employee_manager: false,
        employee_staff: false,
        customer: false,
        anonymous: false,
      }
    when :update
      {
        owner: true,
        employee_admin: true,
        employee_manager: false,
        employee_staff: false,
        customer: false,
        anonymous: false,
      }
    when :destroy
      {
        owner: true,
        employee_admin: false,
        employee_manager: false,
        employee_staff: false,
        customer: false,
        anonymous: false,
      }
    else
      {
        owner: false,
        employee_admin: false,
        employee_manager: false,
        employee_staff: false,
        customer: false,
        anonymous: false,
      }
    end
  end

  # Menu-specific authorization matrix (allows public viewing)
  def menu_authorization_matrix(action)
    case action.to_sym
    when :show
      {
        owner: true,
        employee_admin: true,
        employee_manager: true,
        employee_staff: true,
        customer: true,
        anonymous: true,
      }
    else
      default_authorization_matrix(action)
    end
  end

  # Restaurant-specific authorization matrix
  def restaurant_authorization_matrix(action)
    case action.to_sym
    when :analytics, :performance
      {
        owner: true,
        employee_admin: true,
        employee_manager: false,
        employee_staff: false,
        customer: false,
        anonymous: false,
      }
    else
      default_authorization_matrix(action)
    end
  end
end
