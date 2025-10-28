class MenuPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    # Allow public access for customer viewing (including anonymous and authenticated users)
    true
  end

  def create?
    user.id.present? && (owner_of_restaurant? || employee_admin_of_restaurant?)
  end

  def update?
    owner? || employee_admin? || employee_manager?
  end

  def destroy?
    owner? || employee_admin?
  end

  def regenerate_images?
    owner? || employee_admin?
  end

  def analytics?
    owner? || employee_admin?
  end

  def performance?
    owner? || employee_admin?
  end

  def bulk_update?
    owner? || employee_admin?
  end

  class Scope < Scope
    def resolve
      # Include menus from restaurants owned by user
      owned_ids = scope.joins(:restaurant).where(restaurants: { user_id: user.id }).pluck(:id)

      # Include menus from restaurants where user is an employee
      employee_ids = scope.joins(restaurant: :employees)
        .where(employees: { user: user, status: :active }).pluck(:id)

      # Combine both ID arrays and filter
      all_ids = (owned_ids + employee_ids).uniq

      return scope.none if all_ids.empty?

      scope.where(id: all_ids)
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:restaurant) && record.restaurant

    record.restaurant.user_id == user.id
  end

  def owner_of_restaurant?
    return false unless user && record.respond_to?(:restaurant_id)

    restaurant = Restaurant.find_by(id: record.restaurant_id)
    restaurant&.user_id == user.id
  end

  def authorized_employee?
    return false unless user.present? && record.respond_to?(:restaurant) && record.restaurant

    user.employees.exists?(restaurant_id: record.restaurant.id, status: :active)
  end

  def employee_admin?
    return false unless user.present? && record.respond_to?(:restaurant) && record.restaurant

    user.employees.exists?(restaurant_id: record.restaurant.id, role: :admin, status: :active)
  end

  def employee_manager?
    return false unless user.present? && record.respond_to?(:restaurant) && record.restaurant

    user.employees.exists?(restaurant_id: record.restaurant.id, role: %i[manager admin], status: :active)
  end

  def employee_admin_of_restaurant?
    return false unless user.present? && record.respond_to?(:restaurant_id)

    user.employees.exists?(restaurant_id: record.restaurant_id, role: :admin, status: :active)
  end
end
