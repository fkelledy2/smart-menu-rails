module Employees
  # Employees::RoleChangeService — changes the role of a target employee.
  #
  # Usage:
  #   result = Employees::RoleChangeService.call(
  #     acting_employee: admin_employee,
  #     target_employee: staff_employee,
  #     to_role:         'manager',
  #     reason:          'Promoted for outstanding performance during Q1',
  #   )
  #
  #   result.success? => true / false
  #   result.audit    => EmployeeRoleAudit (when success)
  #   result.error    => String (when failure)
  class RoleChangeService
    Result = Struct.new(:success?, :audit, :error, keyword_init: true)

    # @param acting_employee [Employee] the employee initiating the change
    # @param target_employee [Employee] the employee whose role is being changed
    # @param to_role         [String]   target role name ('staff', 'manager', 'admin')
    # @param reason          [String]   mandatory justification (min 10 chars)
    def self.call(acting_employee:, target_employee:, to_role:, reason:)
      new(
        acting_employee: acting_employee,
        target_employee: target_employee,
        to_role: to_role,
        reason: reason,
      ).call
    end

    def initialize(acting_employee:, target_employee:, to_role:, reason:)
      @acting_employee = acting_employee
      @target_employee = target_employee
      @to_role         = to_role.to_s
      @reason          = reason.to_s.strip
    end

    def call
      error = validate
      return Result.new(success?: false, error: error) if error

      audit = nil

      Employee.transaction do
        from_role = @target_employee.role

        @target_employee.update!(role: @to_role)

        audit = EmployeeRoleAudit.create!(
          employee: @target_employee,
          restaurant: @target_employee.restaurant,
          changed_by: @acting_employee,
          from_role: from_role,
          to_role: @to_role,
          reason: @reason,
        )
      end

      EmployeeRoleChangedJob.perform_later(audit.id)

      Result.new(success?: true, audit: audit)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, error: e.message)
    end

    private

    def validate
      return 'Acting employee is required' if @acting_employee.blank?
      return 'Target employee is required' if @target_employee.blank?
      return 'Cannot change your own role' if @acting_employee.id == @target_employee.id
      return 'Employees must belong to the same restaurant' unless same_restaurant?
      return 'Invalid role' unless valid_role?
      return 'No change: employee already has this role' if @target_employee.role.to_s == @to_role
      return 'Reason must be at least 10 characters' if @reason.length < 10
      return 'Insufficient permissions to make this role change' unless authorised?

      nil
    end

    def same_restaurant?
      @acting_employee.restaurant_id == @target_employee.restaurant_id
    end

    def valid_role?
      Employee.roles.key?(@to_role)
    end

    # Role-change permission matrix:
    #   admin   → can promote/demote any role (staff/manager/admin)
    #   manager → can promote staff to manager only; no other changes
    def authorised?
      return false unless @acting_employee.admin? || @acting_employee.manager?

      @acting_employee.admin? || (@target_employee.staff? && @to_role == 'manager')
    end
  end
end
