require 'test_helper'

class EmployeeRoleAuditTest < ActiveSupport::TestCase
  def setup
    @restaurant     = restaurants(:one)
    @employee       = employees(:staff_member)
    @acting_employee = employees(:one) # manager
    @audit = EmployeeRoleAudit.new(
      employee: @employee,
      restaurant: @restaurant,
      changed_by: @acting_employee,
      from_role: :staff,
      to_role: :manager,
      reason: 'Promoted for outstanding performance this quarter',
    )
  end

  # === VALIDATION TESTS ===

  test 'is valid with valid attributes' do
    assert @audit.valid?, @audit.errors.full_messages.to_s
  end

  test 'requires employee' do
    @audit.employee = nil
    assert_not @audit.valid?
  end

  test 'requires restaurant' do
    @audit.restaurant = nil
    assert_not @audit.valid?
  end

  test 'requires changed_by' do
    @audit.changed_by = nil
    assert_not @audit.valid?
  end

  test 'requires from_role' do
    @audit.from_role = nil
    assert_not @audit.valid?
  end

  test 'requires to_role' do
    @audit.to_role = nil
    assert_not @audit.valid?
  end

  test 'requires reason' do
    @audit.reason = nil
    assert_not @audit.valid?
  end

  test 'requires reason to be at least 10 characters' do
    @audit.reason = 'Short'
    assert_not @audit.valid?
    assert_includes @audit.errors[:reason], 'is too short (minimum is 10 characters)'
  end

  test 'is valid with reason of exactly 10 characters' do
    @audit.reason = '1234567890'
    assert @audit.valid?
  end

  # === ASSOCIATION TESTS ===

  test 'belongs to employee' do
    assert_respond_to @audit, :employee
    assert_instance_of Employee, @audit.employee
  end

  test 'belongs to restaurant' do
    assert_respond_to @audit, :restaurant
    assert_instance_of Restaurant, @audit.restaurant
  end

  test 'belongs to changed_by employee' do
    assert_respond_to @audit, :changed_by
    assert_instance_of Employee, @audit.changed_by
  end

  # === ENUM TESTS ===

  test 'from_role enum uses :from_ prefix' do
    @audit.save!
    assert @audit.from_staff?
    assert_not @audit.from_manager?
    assert_not @audit.from_admin?
  end

  test 'to_role enum uses :to_ prefix' do
    @audit.save!
    assert @audit.to_manager?
    assert_not @audit.to_staff?
    assert_not @audit.to_admin?
  end

  # === IMMUTABILITY TESTS ===

  test 'raises ReadOnlyRecord on update attempt' do
    @audit.save!
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      @audit.update!(reason: 'Trying to change the reason')
    end
  end

  test 'raises ReadOnlyRecord on destroy attempt' do
    @audit.save!
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      @audit.destroy!
    end
  end

  test 'can be created successfully' do
    assert_difference 'EmployeeRoleAudit.count', 1 do
      @audit.save!
    end
  end

  # === DEFAULT SCOPE TESTS ===

  test 'orders by created_at descending by default' do
    @audit.save!
    EmployeeRoleAudit.create!(
      employee: @employee,
      restaurant: @restaurant,
      changed_by: @acting_employee,
      from_role: :manager,
      to_role: :admin,
      reason: 'Further promotion after excellent Q2 results',
      created_at: 1.hour.ago,
    )
    EmployeeRoleAudit.create!(
      employee: @employee,
      restaurant: @restaurant,
      changed_by: @acting_employee,
      from_role: :admin,
      to_role: :manager,
      reason: 'Voluntary step back from admin responsibilities',
      created_at: Time.current,
    )

    audits = EmployeeRoleAudit.where(employee: @employee).to_a
    assert audits.first.created_at >= audits.second.created_at
  end
end
