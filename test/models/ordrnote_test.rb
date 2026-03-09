require 'test_helper'

class OrdrnoteTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @employee = employees(:one)
    @ordr = ordrs(:one)

    @note = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Customer has severe nut allergy',
      category: 'dietary',
      priority: 'urgent',
    )
  end

  # Validations
  test 'should be valid with valid attributes' do
    assert @note.valid?
  end

  test 'should require content' do
    @note.content = nil
    assert_not @note.valid?
    assert_includes @note.errors[:content], "can't be blank"
  end

  test 'should require minimum content length' do
    @note.content = 'ab'
    assert_not @note.valid?
    assert_includes @note.errors[:content], 'is too short (minimum is 3 characters)'
  end

  test 'should enforce maximum content length' do
    @note.content = 'a' * 501
    assert_not @note.valid?
    assert_includes @note.errors[:content], 'is too long (maximum is 500 characters)'
  end

  test 'should require category' do
    @note.category = nil
    assert_not @note.valid?
  end

  test 'should require priority' do
    @note.priority = nil
    assert_not @note.valid?
  end

  # Associations
  test 'should belong to ordr' do
    assert_equal @ordr, @note.ordr
  end

  test 'should belong to employee' do
    assert_equal @employee, @note.employee
  end

  # Enums
  test 'should have dietary category' do
    @note.category = 'dietary'
    assert @note.dietary?
  end

  test 'should have preparation category' do
    @note.category = 'preparation'
    assert @note.preparation?
  end

  test 'should have timing category' do
    @note.category = 'timing'
    assert @note.timing?
  end

  test 'should have customer_service category' do
    @note.category = 'customer_service'
    assert @note.customer_service?
  end

  test 'should have operational category' do
    @note.category = 'operational'
    assert @note.operational?
  end

  test 'should have low priority' do
    @note.priority = 'low'
    assert @note.low?
  end

  test 'should have medium priority' do
    @note.priority = 'medium'
    assert @note.medium?
  end

  test 'should have high priority' do
    @note.priority = 'high'
    assert @note.high?
  end

  test 'should have urgent priority' do
    @note.priority = 'urgent'
    assert @note.urgent?
  end

  # Scopes
  test 'active scope should return non-expired notes' do
    active_note = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Active note',
      category: 'dietary',
      priority: 'medium',
    )

    expired_note = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Expired note',
      category: 'dietary',
      priority: 'medium',
      expires_at: 1.hour.ago,
    )

    active_notes = @ordr.ordrnotes.active
    assert_includes active_notes, active_note
    assert_not_includes active_notes, expired_note
  end

  test 'for_kitchen scope should return kitchen-visible notes' do
    kitchen_note = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Kitchen note',
      category: 'preparation',
      priority: 'medium',
      visible_to_kitchen: true,
    )

    non_kitchen_note = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Non-kitchen note',
      category: 'operational',
      priority: 'medium',
      visible_to_kitchen: false,
    )

    kitchen_notes = @ordr.ordrnotes.for_kitchen
    assert_includes kitchen_notes, kitchen_note
    assert_not_includes kitchen_notes, non_kitchen_note
  end

  test 'for_servers scope should return server-visible notes' do
    server_note = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Server note',
      category: 'customer_service',
      priority: 'medium',
      visible_to_servers: true,
    )

    non_server_note = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Non-server note',
      category: 'operational',
      priority: 'medium',
      visible_to_servers: false,
    )

    server_notes = @ordr.ordrnotes.for_servers
    assert_includes server_notes, server_note
    assert_not_includes server_notes, non_server_note
  end

  test 'for_customers scope should return customer-visible notes' do
    customer_note = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Customer note',
      category: 'preparation',
      priority: 'medium',
      visible_to_customers: true,
    )

    non_customer_note = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Non-customer note',
      category: 'operational',
      priority: 'medium',
      visible_to_customers: false,
    )

    customer_notes = @ordr.ordrnotes.for_customers
    assert_includes customer_notes, customer_note
    assert_not_includes customer_notes, non_customer_note
  end

  test 'by_priority scope should order by priority desc then created_at desc' do
    # Clear existing notes
    @ordr.ordrnotes.destroy_all

    @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Low priority',
      category: 'operational',
      priority: 'low',
    )

    @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'High priority',
      category: 'timing',
      priority: 'high',
    )

    @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Urgent priority',
      category: 'dietary',
      priority: 'urgent',
    )

    ordered_notes = @ordr.ordrnotes.by_priority.to_a
    # Priority ordering: urgent (3) > high (2) > low (0)
    # Within same priority, newer (higher created_at) comes first
    priorities = ordered_notes.map(&:priority)
    assert_equal 'urgent', priorities[0]
    assert_equal 'high', priorities[1]
    assert_equal 'low', priorities[2]
  end

  test 'dietary_notes scope should return only dietary notes' do
    dietary_note = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Dietary note',
      category: 'dietary',
      priority: 'high',
    )

    prep_note = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Prep note',
      category: 'preparation',
      priority: 'medium',
    )

    dietary_notes = @ordr.ordrnotes.dietary_notes
    assert_includes dietary_notes, dietary_note
    assert_not_includes dietary_notes, prep_note
  end

  test 'urgent_notes scope should return high and urgent priority notes' do
    urgent_note = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Urgent note',
      category: 'dietary',
      priority: 'urgent',
    )

    high_note = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'High note',
      category: 'timing',
      priority: 'high',
    )

    medium_note = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Medium note',
      category: 'operational',
      priority: 'medium',
    )

    urgent_notes = @ordr.ordrnotes.urgent_notes
    assert_includes urgent_notes, urgent_note
    assert_includes urgent_notes, high_note
    assert_not_includes urgent_notes, medium_note
  end

  # Instance methods
  test 'expired? should return true for expired notes' do
    @note.expires_at = 1.hour.ago
    assert @note.expired?
  end

  test 'expired? should return false for non-expired notes' do
    @note.expires_at = 1.hour.from_now
    assert_not @note.expired?
  end

  test 'expired? should return false for notes without expiry' do
    @note.expires_at = nil
    assert_not @note.expired?
  end

  test 'high_priority? should return true for urgent notes' do
    @note.priority = 'urgent'
    assert @note.high_priority?
  end

  test 'high_priority? should return true for high notes' do
    @note.priority = 'high'
    assert @note.high_priority?
  end

  test 'high_priority? should return false for medium notes' do
    @note.priority = 'medium'
    assert_not @note.high_priority?
  end

  test 'high_priority? should return false for low notes' do
    @note.priority = 'low'
    assert_not @note.high_priority?
  end

  test 'editable_by? should allow creator within 15 minutes' do
    @note.update_column(:created_at, 10.minutes.ago)
    assert @note.editable_by?(@employee.user)
  end

  test 'editable_by? should not allow creator after 15 minutes' do
    @note.update_column(:created_at, 20.minutes.ago)
    assert_not @note.editable_by?(@employee.user)
  end

  test 'editable_by? should allow managers anytime' do
    manager_user = User.create!(email: 'manager@test.com', password: 'password123')
    manager = @restaurant.employees.create!(
      user: manager_user,
      name: 'Manager User',
      eid: 'MGR001',
      role: 'manager',
      status: 'active',
    )
    @note.update_column(:created_at, 1.day.ago)

    assert @note.editable_by?(manager.user)
  end

  test 'editable_by? should allow admins anytime' do
    admin_user = User.create!(email: 'admin@test.com', password: 'password123')
    admin = @restaurant.employees.create!(
      user: admin_user,
      name: 'Admin User',
      eid: 'ADM001',
      role: 'admin',
      status: 'active',
    )
    @note.update_column(:created_at, 1.day.ago)

    assert @note.editable_by?(admin.user)
  end

  # Helper methods
  test 'category_icon should return correct icon for dietary' do
    @note.category = 'dietary'
    assert_equal '🚨', @note.category_icon
  end

  test 'category_icon should return correct icon for preparation' do
    @note.category = 'preparation'
    assert_equal '👨‍🍳', @note.category_icon
  end

  test 'category_icon should return correct icon for timing' do
    @note.category = 'timing'
    assert_equal '⏰', @note.category_icon
  end

  test 'category_icon should return correct icon for customer_service' do
    @note.category = 'customer_service'
    assert_equal '💬', @note.category_icon
  end

  test 'category_icon should return correct icon for operational' do
    @note.category = 'operational'
    assert_equal '🔧', @note.category_icon
  end

  test 'category_color should return danger for dietary' do
    @note.category = 'dietary'
    assert_equal 'danger', @note.category_color
  end

  test 'category_color should return info for preparation' do
    @note.category = 'preparation'
    assert_equal 'info', @note.category_color
  end

  test 'category_color should return warning for timing' do
    @note.category = 'timing'
    assert_equal 'warning', @note.category_color
  end

  test 'category_color should return success for customer_service' do
    @note.category = 'customer_service'
    assert_equal 'success', @note.category_color
  end

  test 'category_color should return secondary for operational' do
    @note.category = 'operational'
    assert_equal 'secondary', @note.category_color
  end

  test 'priority_color should return danger for urgent' do
    @note.priority = 'urgent'
    assert_equal 'danger', @note.priority_color
  end

  test 'priority_color should return warning for high' do
    @note.priority = 'high'
    assert_equal 'warning', @note.priority_color
  end

  test 'priority_color should return info for medium' do
    @note.priority = 'medium'
    assert_equal 'info', @note.priority_color
  end

  test 'priority_color should return secondary for low' do
    @note.priority = 'low'
    assert_equal 'secondary', @note.priority_color
  end

  # Default values
  test 'should have default visibility settings' do
    new_note = @ordr.ordrnotes.build(
      employee: @employee,
      content: 'Test note',
      category: 'dietary',
      priority: 'medium',
    )
    new_note.save!

    assert new_note.visible_to_kitchen
    assert new_note.visible_to_servers
    assert_not new_note.visible_to_customers
  end
end
