# EmployeeRoleAuditPolicy — append-only audit records.
# No update or destroy actions are ever permitted via the application.
class EmployeeRoleAuditPolicy < ApplicationPolicy
  def index?
    owner_or_manager?
  end

  def show?
    owner_or_manager?
  end

  def create?
    false # Created exclusively by Employees::RoleChangeService, not directly
  end

  def update?
    false
  end

  def destroy?
    false
  end

  class Scope < Scope
    def resolve
      scope.joins(:restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner_or_manager?
    return false unless user.present? && user.persisted?

    return true if record.respond_to?(:restaurant) && record.restaurant&.user_id == user.id

    acting_employee = user.employees.find_by(restaurant_id: record.restaurant_id)
    acting_employee&.manager? || acting_employee&.admin?
  end
end
