class OrdrnotePolicy < ApplicationPolicy
  def index?
    # For class-level authorization (e.g., authorize Ordrnote), just check if user is present
    return user.present? if record.is_a?(Class)
    
    user_is_restaurant_employee?
  end

  def show?
    user_is_restaurant_employee?
  end

  def create?
    user_is_restaurant_employee?
  end

  def update?
    return false unless user_is_restaurant_employee?

    # Employee who created the note can edit within 15 minutes
    if record.employee.user_id == user.id
      return record.created_at > 15.minutes.ago
    end

    # Managers and admins can always edit
    user_is_manager?
  end

  def destroy?
    return false unless user_is_restaurant_employee?

    # Employee who created the note can delete within 15 minutes
    if record.employee.user_id == user.id
      return record.created_at > 15.minutes.ago
    end

    # Managers and admins can always delete
    user_is_manager?
  end

  class Scope < Scope
    def resolve
      if user
        # Return notes for orders in restaurants where user is an employee
        restaurant_ids = user.employees.pluck(:restaurant_id)
        scope.joins(:ordr).where(ordrs: { restaurant_id: restaurant_ids })
      else
        scope.none
      end
    end
  end

  private

  def user_is_restaurant_employee?
    return false unless user

    record.ordr.restaurant.employees.exists?(user: user)
  end

  def user_is_manager?
    return false unless user

    employee = record.ordr.restaurant.employees.find_by(user: user)
    employee&.manager? || employee&.admin?
  end
end
