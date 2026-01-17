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
  
  def update_availabilities?
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
      return scope.none unless user.present?

      owned_restaurant_ids = Restaurant.where(user_id: user.id).select(:id)
      employee_restaurant_ids = Employee.where(user: user, status: :active).select(:restaurant_id)

      accessible_restaurant_ids = Restaurant.where(id: owned_restaurant_ids)
        .or(Restaurant.where(id: employee_restaurant_ids))
        .select(:id)

      scope
        .left_joins(:restaurant_menus)
        .where(
          'menus.restaurant_id IN (?) OR restaurant_menus.restaurant_id IN (?)',
          accessible_restaurant_ids,
          accessible_restaurant_ids,
        )
        .distinct
    end
  end

  private

  def owner?
    return false unless record

    owner_restaurant = record.respond_to?(:owner_restaurant) && record.owner_restaurant.present? ? record.owner_restaurant : record.restaurant
    return false unless user && owner_restaurant

    owner_restaurant.user_id == user.id
  end

  def owner_of_restaurant?
    return false unless user && record.respond_to?(:restaurant_id)

    restaurant = Restaurant.find_by(id: record.restaurant_id)
    restaurant&.user_id == user.id
  end

  def authorized_employee?
    return false unless record

    owner_restaurant = record.respond_to?(:owner_restaurant) && record.owner_restaurant.present? ? record.owner_restaurant : record.restaurant
    return false unless user.present? && owner_restaurant

    user.employees.exists?(restaurant_id: owner_restaurant.id, status: :active)
  end

  def employee_admin?
    return false unless record

    owner_restaurant = record.respond_to?(:owner_restaurant) && record.owner_restaurant.present? ? record.owner_restaurant : record.restaurant
    return false unless user.present? && owner_restaurant

    user.employees.exists?(restaurant_id: owner_restaurant.id, role: :admin, status: :active)
  end

  def employee_manager?
    return false unless record

    owner_restaurant = record.respond_to?(:owner_restaurant) && record.owner_restaurant.present? ? record.owner_restaurant : record.restaurant
    return false unless user.present? && owner_restaurant

    user.employees.exists?(restaurant_id: owner_restaurant.id, role: %i[manager admin], status: :active)
  end

  def employee_admin_of_restaurant?
    return false unless user.present? && record.respond_to?(:restaurant_id)

    user.employees.exists?(restaurant_id: record.restaurant_id, role: :admin, status: :active)
  end
end
