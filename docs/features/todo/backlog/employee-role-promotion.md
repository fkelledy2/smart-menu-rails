# Employee Role Promotion System

## Overview
Implement a role promotion system allowing restaurant managers to promote staff members to higher roles (staff → manager → admin) with proper authorization, audit trails, and permissions management.

## Business Value
- **Scalability**: Enables restaurants to grow their management team organically
- **Empowerment**: Allows trusted staff to take on more responsibility
- **Efficiency**: Reduces dependency on single administrators
- **Accountability**: Clear audit trail for role changes and permissions

## User Stories

### Restaurant Owner/Admin
- As a restaurant owner, I want to promote a trusted staff member to manager so they can help manage daily operations
- As a restaurant owner, I want to promote a manager to admin so they can handle sensitive business functions
- As a restaurant owner, I want to see the history of role changes for accountability
- As a restaurant owner, I want to set up approval workflows for role promotions

### Manager
- As a manager, I want to request promotion to admin so I can access additional business features
- As a manager, I want to see what permissions I'll gain at each role level
- As a manager, I want to promote capable staff to help with daily tasks

### Staff Member
- As a staff member, I want to be considered for promotion to manager based on my performance
- As a staff member, I want to understand the responsibilities of higher roles
- As a staff member, I want to receive proper training when promoted

### System Administrator
- As a system admin, I want to monitor role changes across all restaurants
- As a system admin, I want to enforce minimum requirements for role promotions
- As a system admin, I want to review and audit role change requests

## Technical Requirements

### Data Model Changes

#### User Model Enhancements
```ruby
# Add role hierarchy
add_column :users, :role_level, :integer, default: 0  # 0: staff, 1: manager, 2: admin
add_column :users, :role_promoted_at, :datetime
add_column :users, :role_promoted_by_id, :bigint
add_column :users, :role_requested_at, :datetime
add_column :users, :role_requested_to, :integer  # Target role level
add_column :users, :role_request_reason, :text

# Indexes
add_index :users, :role_level
add_index :users, :role_promoted_by_id
```

#### RolePromotion Model (New)
```ruby
create_table :role_promotions do |t|
  t.references :user, null: false, foreign_key: true
  t.references :promoted_by, foreign_key: { to_table: :users }
  t.integer :from_role, null: false
  t.integer :to_role, null: false
  t.text :reason
  t.text :notes
  t.datetime :effective_at
  t.datetime :approved_at
  t.datetime :rejected_at
  t.references :approved_by, foreign_key: { to_table: :users }
  t.references :rejected_by, foreign_key: { to_table: :users }
  t.text :rejection_reason
  t.timestamps
  
  t.index :user_id
  t.index :promoted_by_id
  t.index :effective_at
end
```

#### RolePermission Model (New)
```ruby
create_table :role_permissions do |t|
  t.string :role, null: false  # 'staff', 'manager', 'admin'
  t.string :permission, null: false
  t.text :description
  t.timestamps
  
  t.index [:role, :permission], unique: true
end
```

### Role Hierarchy Definition

#### Staff (Level 0)
- View assigned menus and take orders
- Manage own profile
- View order history
- Basic operational functions

#### Manager (Level 1)
- All staff permissions
- Manage menu items and pricing
- View and edit orders
- Manage staff schedules
- Access basic reports
- Promote staff to manager role

#### Admin (Level 2)
- All manager permissions
- Manage restaurant settings
- Access financial reports
- Manage billing and subscriptions
- Promote managers to admin role
- Full restaurant control

### Authorization System

#### Pundit Policy Updates
```ruby
# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  def promote_to_manager?
    user.admin? || user.manager?
  end
  
  def promote_to_admin?
    user.admin?
  end
  
  def view_role_history?
    user.admin? || user.manager?
  end
  
  def request_promotion?
    user.staff? || user.manager?
  end
end

# app/policies/role_promotion_policy.rb
class RolePromotionPolicy < ApplicationPolicy
  def create?
    can_promote?
  end
  
  def approve?
    user.admin? && record.to_role <= 2
  end
  
  private
  
  def can_promote?
    case record.to_role
    when 1  # to manager
      user.admin? || user.manager?
    when 2  # to admin
      user.admin?
    else
      false
    end
  end
end
```

### API Changes

#### Role Management Endpoints
```ruby
# GET /api/v1/users/:id/role_history
# Response: List of role promotions

# POST /api/v1/users/:id/promote
{
  "to_role": 1,  # 1: manager, 2: admin
  "reason": "Excellent performance and leadership",
  "effective_at": "2024-01-01T00:00:00Z"
}

# POST /api/v1/users/request_promotion
{
  "requested_role": 1,
  "reason": "Ready for more responsibility"
}

# GET /api/v1/role_permissions
# Response: Available permissions for each role

# GET /api/v1/users/:id/promotion_eligibility
# Response: Whether user can be promoted and requirements
```

#### User Profile Enhancements
```json
{
  "id": 123,
  "name": "John Doe",
  "email": "john@example.com",
  "role": "manager",
  "role_level": 1,
  "role_promoted_at": "2024-01-15T10:30:00Z",
  "can_promote_to": ["staff"],
  "can_be_promoted_to": ["admin"],
  "pending_promotion_request": {
    "requested_role": 2,
    "requested_at": "2024-02-01T09:00:00Z",
    "status": "pending"
  }
}
```

### UI/UX Requirements

#### User Management Interface
- Role promotion buttons with proper authorization
- Role history timeline
- Promotion request forms
- Approval/rejection workflows
- Bulk promotion capabilities

#### Role Promotion Modal
- Target role selection
- Reason input (required)
- Effective date picker
- Preview of new permissions
- Confirmation step

#### Promotion Request Interface
- Available roles display
- Role requirements and responsibilities
- Request reason textarea
- Status tracking
- Withdrawal option

#### Admin Dashboard
- Pending promotion requests
- Role distribution analytics
- Promotion history reports
- Approval workflows

### Business Logic

#### Promotion Eligibility
```ruby
class RolePromotionService
  def can_promote?(promoter, target_user, to_role)
    return false unless promoter && target_user
    
    case to_role
    when 1  # to manager
      promoter.admin? || promoter.manager?
    when 2  # to admin
      promoter.admin?
    else
      false
    end && target_user.role_level < to_role
  end
  
  def promote_user(promoter, target_user, to_role, reason, effective_at = Time.current)
    return false unless can_promote?(promoter, target_user, to_role)
    
    ActiveRecord::Base.transaction do
      # Create promotion record
      promotion = RolePromotion.create!(
        user: target_user,
        promoted_by: promoter,
        from_role: target_user.role_level,
        to_role: to_role,
        reason: reason,
        effective_at: effective_at,
        approved_at: Time.current,
        approved_by: promoter
      )
      
      # Update user role
      target_user.update!(
        role_level: to_role,
        role_promoted_at: effective_at,
        role_promoted_by: promoter
      )
      
      # Send notifications
      send_promotion_notifications(target_user, promoter, to_role)
      
      promotion
    end
  end
end
```

#### Permission System
```ruby
class RolePermissionService
  PERMISSIONS = {
    'staff' => [
      'view_menus',
      'take_orders',
      'manage_profile'
    ],
    'manager' => [
      'view_menus',
      'take_orders',
      'manage_profile',
      'manage_menu_items',
      'manage_orders',
      'view_reports',
      'promote_staff'
    ],
    'admin' => [
      'view_menus',
      'take_orders',
      'manage_profile',
      'manage_menu_items',
      'manage_orders',
      'view_reports',
      'promote_staff',
      'manage_restaurant',
      'manage_billing',
      'promote_managers'
    ]
  }.freeze
  
  def self.permissions_for_role(role)
    PERMISSIONS[role] || []
  end
  
  def self.has_permission?(user, permission)
    role = user.role_level
    permissions_for_role(role).include?(permission)
  end
end
```

### Implementation Phases

#### Phase 1: Foundation
1. Database migrations
2. Role hierarchy implementation
3. Basic promotion service
4. Authorization policies

#### Phase 2: User Interface
1. User management enhancements
2. Promotion modals and forms
3. Role history display
4. Request system

#### Phase 3: Advanced Features
1. Approval workflows
2. Bulk promotions
3. Analytics dashboard
4. Notification system

#### Phase 4: Security & Audit
1. Comprehensive audit trails
2. Security monitoring
3. Compliance reporting
4. Admin override tools

### Testing Requirements

#### Unit Tests
- Promotion eligibility logic
- Permission system
- Role validation
- Notification sending

#### Integration Tests
- API endpoint security
- Database transactions
- Permission checks
- Email delivery

#### System Tests
- Complete promotion workflows
- Authorization boundaries
- UI interactions
- Multi-user scenarios

### Security Considerations

#### Authorization Controls
- Strict role-based access control
- Promotion limits based on current role
- Audit logging for all role changes
- Session invalidation on role change

#### Validation Rules
- Cannot promote to equal or lower role
- Cannot promote self
- Minimum time in current role
- Required reason for promotion

#### Audit Trail
- Complete history of all role changes
- Who initiated the change
- When and why it occurred
- Approval/rejection tracking

### Performance Considerations
- Efficient permission checking (cached)
- Minimal database queries for role validation
- Optimized audit trail queries
- Scalable notification system

### Dependencies
- No external dependencies required
- Integrates with existing user system
- Compatible with current authorization framework

### Rollout Strategy
1. Internal testing with admin users
2. Beta with select restaurants
3. Gradual rollout to all restaurants
4. Training materials and documentation
5. Support and monitoring
