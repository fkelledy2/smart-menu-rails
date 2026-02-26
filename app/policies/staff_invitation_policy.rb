class StaffInvitationPolicy < ApplicationPolicy
  def create?
    return false unless user && record.respond_to?(:restaurant)

    record.restaurant&.user_id == user.id ||
      user.admin_employee_for_restaurant?(record.restaurant_id) ||
      user.manager_employee_for_restaurant?(record.restaurant_id)
  end

  def destroy?
    create?
  end

  class Scope < Scope
    def resolve
      scope.joins(:restaurant).where(restaurants: { user_id: user.id })
    end
  end
end
