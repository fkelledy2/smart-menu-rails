# Authorization Policy Validation Plan

## 🎯 **Executive Summary**

This document outlines a comprehensive plan to validate authorization policies across all user roles in the Smart Menu Rails application. The goal is to ensure that every user role has appropriate access controls and that authorization policies are consistently enforced across all complex controllers.

**Current Status**: Authorization policies exist but lack comprehensive validation across all user roles and edge cases.

**Target**: 100% authorization policy validation coverage with automated testing for all user roles and permission scenarios.

---

## 📊 **Current Authorization Architecture Analysis**

### **User Roles Identified**

1. **Restaurant Owners** (`user.restaurants.any?`)
   - Primary role for restaurant management
   - Full access to their own restaurant data
   - Cannot access other restaurants' data

2. **Employees** (`Employee` model with roles)
   - **Staff** (`role: :staff`) - Basic operational access
   - **Manager** (`role: :manager`) - Enhanced operational access
   - **Admin** (`role: :admin`) - Administrative access within restaurant

3. **Customers/Anonymous Users**
   - Can view public menus
   - Limited to read-only operations on public data
   - No access to management interfaces

4. **System Administrators**
   - Access to admin controllers (`Admin::*`)
   - System-wide monitoring and management capabilities

### **Current Policy Structure**

```ruby
# Base Policy Pattern
class ApplicationPolicy
  def initialize(user, record)
    @user = user || User.new # Guest user
    @record = record
  end
  
  # Default deny-all approach
  def index?; false; end
  def show?; false; end
  def create?; false; end
  def update?; false; end
  def destroy?; false; end
end
```

### **Key Policies Analyzed**

1. **RestaurantPolicy** - Owner-based access control
2. **MenuPolicy** - Mixed public/owner access
3. **EmployeePolicy** - Restaurant owner control
4. **OrdrPolicy** - Complex multi-user access
5. **Admin Policies** - System administrator access

---

## 🔍 **Authorization Gaps Identified**

### **1. Employee Role-Based Access Control**
- **Gap**: Employee roles (staff/manager/admin) not consistently enforced
- **Risk**: Employees may have inappropriate access levels
- **Impact**: Medium - Potential privilege escalation within restaurants

### **2. Cross-Restaurant Data Leakage**
- **Gap**: Insufficient validation of restaurant ownership in complex queries
- **Risk**: Users accessing other restaurants' data
- **Impact**: High - Data privacy violation

### **3. Anonymous User Access Control**
- **Gap**: Inconsistent handling of anonymous users across controllers
- **Risk**: Unauthorized access to sensitive data
- **Impact**: Medium - Information disclosure

### **4. API Endpoint Authorization**
- **Gap**: JSON API endpoints may have different authorization rules
- **Risk**: API bypass of web interface restrictions
- **Impact**: High - Complete authorization bypass

### **5. Nested Resource Authorization**
- **Gap**: Complex nested resources (restaurant/menu/items) may not validate full chain
- **Risk**: Access to resources through unauthorized parent resources
- **Impact**: Medium - Indirect access to restricted data

---

## 🛠 **Validation Strategy**

### **Phase 1: Policy Audit and Enhancement**

#### **1.1 Comprehensive Policy Review**
- Audit all 46 existing policies for consistency
- Identify missing role-based checks
- Document expected behavior for each user role

#### **1.2 Employee Role Integration**
- Enhance policies to support employee roles
- Implement role-based permissions within restaurants
- Create employee access matrices

#### **1.3 Cross-Restaurant Validation**
- Strengthen restaurant ownership checks
- Implement consistent scoping across all policies
- Add validation for nested resource chains

### **Phase 2: Automated Testing Implementation**

#### **2.1 Role-Based Test Suite**
- Create test fixtures for each user role
- Implement comprehensive permission testing
- Test both positive and negative authorization cases

#### **2.2 Edge Case Testing**
- Test unauthorized access attempts
- Validate cross-restaurant data isolation
- Test API vs web interface consistency

#### **2.3 Integration Testing**
- Test complex workflows across multiple controllers
- Validate authorization in real-world scenarios
- Test performance impact of authorization checks

### **Phase 3: Monitoring and Validation**

#### **3.1 Authorization Monitoring**
- Implement authorization failure logging
- Create dashboards for authorization metrics
- Set up alerts for suspicious access patterns

#### **3.2 Continuous Validation**
- Add authorization tests to CI/CD pipeline
- Implement automated policy regression testing
- Create authorization coverage reporting

---

## 🎯 **Implementation Plan**

### **Week 1: Foundation**
- [ ] Complete policy audit and documentation
- [ ] Identify all authorization gaps
- [ ] Create user role test fixtures
- [ ] Design authorization test framework

### **Week 2: Core Implementation**
- [ ] Enhance employee role-based policies
- [ ] Strengthen cross-restaurant validation
- [ ] Implement comprehensive test suite
- [ ] Add authorization monitoring

### **Week 3: Advanced Features**
- [ ] Test complex authorization scenarios
- [ ] Implement API authorization validation
- [ ] Add performance optimization
- [ ] Create authorization documentation

### **Week 4: Validation and Deployment**
- [ ] Run comprehensive test suite
- [ ] Fix any authorization failures
- [ ] Deploy monitoring and alerting
- [ ] Update documentation and roadmap

---

## 📋 **Detailed Implementation Tasks**

### **Task 1: Policy Enhancement**

#### **1.1 Employee Role-Based Policies**
```ruby
# Enhanced policy with employee role support
class MenuPolicy < ApplicationPolicy
  def update?
    owner? || authorized_employee?
  end
  
  private
  
  def authorized_employee?
    return false unless user.present?
    
    employee = user.employees.joins(:restaurant)
                   .find_by(restaurants: { id: record.restaurant_id })
    
    employee&.manager? || employee&.admin?
  end
end
```

#### **1.2 Cross-Restaurant Validation**
```ruby
# Strengthen restaurant ownership validation
class RestaurantPolicy < ApplicationPolicy
  def show?
    owner? || authorized_employee?
  end
  
  private
  
  def owner?
    return false unless user && record
    record.user_id == user.id
  end
  
  def authorized_employee?
    return false unless user.present?
    user.employees.exists?(restaurant_id: record.id)
  end
end
```

### **Task 2: Comprehensive Test Suite**

#### **2.1 Role-Based Test Framework**
```ruby
# Authorization test helper
module AuthorizationTestHelper
  def test_authorization_for_all_roles(action, resource)
    roles = [:owner, :employee_admin, :employee_manager, :employee_staff, :customer, :anonymous]
    
    roles.each do |role|
      user = create_user_with_role(role)
      result = policy_for(user, resource).public_send("#{action}?")
      
      assert_equal expected_result(role, action), result,
        "#{role} should #{expected_result(role, action) ? 'be allowed' : 'be denied'} #{action}"
    end
  end
end
```

#### **2.2 Cross-Restaurant Isolation Tests**
```ruby
# Test cross-restaurant data isolation
class CrossRestaurantAuthorizationTest < ActiveSupport::TestCase
  test "restaurant owner cannot access other restaurant data" do
    owner1 = users(:restaurant_owner_1)
    owner2 = users(:restaurant_owner_2)
    restaurant2 = restaurants(:restaurant_2)
    
    policy = RestaurantPolicy.new(owner1, restaurant2)
    
    refute policy.show?, "Owner should not access other restaurant"
    refute policy.update?, "Owner should not update other restaurant"
    refute policy.destroy?, "Owner should not delete other restaurant"
  end
end
```

### **Task 3: Authorization Monitoring**

#### **3.1 Authorization Failure Logging**
```ruby
# Enhanced application controller with authorization logging
class ApplicationController < ActionController::Base
  rescue_from Pundit::NotAuthorizedError do |exception|
    # Log authorization failure for monitoring
    Rails.logger.warn "Authorization failed: #{exception.message}", {
      user_id: current_user&.id,
      controller: controller_name,
      action: action_name,
      resource: exception.record&.class&.name,
      resource_id: exception.record&.id
    }
    
    redirect_to root_path, alert: 'You are not authorized to perform this action.'
  end
end
```

#### **3.2 Authorization Metrics**
```ruby
# Authorization metrics tracking
class AuthorizationMetrics
  def self.track_authorization_check(user, resource, action, result)
    Rails.logger.info "Authorization check", {
      user_id: user&.id,
      user_role: determine_user_role(user),
      resource_type: resource.class.name,
      action: action,
      result: result,
      timestamp: Time.current
    }
  end
end
```

---

## 🧪 **Testing Strategy**

### **Test Categories**

1. **Unit Tests** - Individual policy method testing
2. **Integration Tests** - Controller authorization testing
3. **System Tests** - End-to-end authorization workflows
4. **Performance Tests** - Authorization overhead measurement

### **Test Coverage Goals**

- **100% Policy Method Coverage** - Every policy method tested
- **100% Role Coverage** - Every user role tested for every action
- **100% Edge Case Coverage** - All authorization edge cases tested
- **95% Controller Coverage** - Authorization tested in all controllers

### **Test Fixtures**

```ruby
# Comprehensive user role fixtures
users:
  restaurant_owner:
    email: "owner@example.com"
    first_name: "Restaurant"
    last_name: "Owner"
    
  employee_admin:
    email: "admin@example.com"
    first_name: "Employee"
    last_name: "Admin"
    
  employee_manager:
    email: "manager@example.com"
    first_name: "Employee"
    last_name: "Manager"
    
  employee_staff:
    email: "staff@example.com"
    first_name: "Employee"
    last_name: "Staff"
    
  customer:
    email: "customer@example.com"
    first_name: "Customer"
    last_name: "User"

employees:
  admin_employee:
    user: employee_admin
    restaurant: restaurant_one
    role: admin
    status: active
    
  manager_employee:
    user: employee_manager
    restaurant: restaurant_one
    role: manager
    status: active
    
  staff_employee:
    user: employee_staff
    restaurant: restaurant_one
    role: staff
    status: active
```

---

## 📊 **Success Metrics**

### **Security Metrics**
- **Zero authorization bypass incidents** in production
- **100% policy test coverage** across all user roles
- **<1% authorization failure rate** in normal operations
- **Zero cross-restaurant data leakage** incidents

### **Performance Metrics**
- **<5ms authorization overhead** per request
- **<2% performance impact** from authorization checks
- **99.9% authorization check reliability**

### **Quality Metrics**
- **100% controller authorization coverage**
- **Zero missing authorization checks** in new code
- **100% documentation coverage** for authorization policies

---

## 🔄 **Maintenance and Evolution**

### **Ongoing Responsibilities**

1. **Policy Review** - Quarterly review of all authorization policies
2. **Role Evolution** - Support for new user roles and permissions
3. **Security Updates** - Regular security assessment and updates
4. **Performance Monitoring** - Continuous authorization performance tracking

### **Future Enhancements**

1. **Fine-Grained Permissions** - Attribute-level authorization
2. **Dynamic Roles** - Runtime role assignment and modification
3. **Audit Trail** - Comprehensive authorization audit logging
4. **Machine Learning** - Anomaly detection for authorization patterns

---

## 📚 **References and Resources**

### **Documentation**
- [Pundit Authorization Gem](https://github.com/varvet/pundit)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [OWASP Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)

### **Internal Documentation**
- `docs/security/penetration_testing_plan.md`
- `docs/security/security-audit-report.md`
- `docs/testing/` - Existing test documentation

This comprehensive plan ensures that authorization policies are thoroughly validated across all user roles, providing robust security while maintaining system performance and usability.
