class RestaurantPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    owner? || authorized_employee?
  end

  def create?
    user.present?
  end

  def update?
    owner? || employee_admin?
  end

  def destroy?
    owner? # Only owners can delete restaurants
  end

  def analytics?
    owner? || employee_admin?
  end

  def performance?
    owner? || employee_admin?
  end

  def user_activity?
    owner? || employee_admin?
  end

  def spotify_auth?
    owner? || employee_admin?
  end

  def spotify_callback?
    owner? || employee_admin?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      # Include restaurants owned by user
      owned_ids = scope.where(user: user).pluck(:id)
      
      # Include restaurants where user is an employee
      employee_ids = scope.joins(:employees).where(employees: { user: user, status: :active }).pluck(:id)
      
      # Combine both ID arrays and filter
      all_ids = (owned_ids + employee_ids).uniq
      
      return scope.none if all_ids.empty?
      
      scope.where(id: all_ids)
    end
  end

  private

  def owner?
    return false unless user && record

    record.user_id == user.id
  end

  def authorized_employee?
    return false unless user.present? && record

    user.employees.exists?(restaurant_id: record.id, status: :active)
  end

  def employee_admin?
    return false unless user.present? && record

    user.employees.exists?(restaurant_id: record.id, role: :admin, status: :active)
  end

  def employee_manager?
    return false unless user.present? && record

    user.employees.exists?(restaurant_id: record.id, role: [:manager, :admin], status: :active)
  end
end
