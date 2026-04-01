class EmployeePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    owner?
  end

  def create?
    user.present?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  # Can the acting user change this employee's role?
  # admin  → can change any role in their restaurant
  # manager → can only promote staff → manager
  # No one can change their own role.
  def change_role?
    return false unless user.present? && user.persisted?
    return false if acting_employee.nil?
    return false if acting_employee.id == record.id

    acting_employee.admin? ||
      (acting_employee.manager? && record.staff?)
  end

  # Managers and admins may view the audit history for an employee.
  def view_role_history?
    return false unless user.present? && user.persisted?

    acting_employee&.manager? || acting_employee&.admin?
  end

  class Scope < Scope
    def resolve
      scope.joins(:restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:restaurant)

    record.restaurant&.user_id == user.id
  end

  # Returns the Employee record for the acting user scoped to the target
  # employee's restaurant. Memoised per-record to avoid repeated queries.
  def acting_employee
    return @acting_employee if defined?(@acting_employee)

    restaurant_id = record.respond_to?(:restaurant_id) ? record.restaurant_id : nil
    @acting_employee = restaurant_id ? user.employees.find_by(restaurant_id: restaurant_id) : nil
  end
end
