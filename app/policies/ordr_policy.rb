class OrdrPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    # Allow access for owners and employees only
    return false if user.id.nil? # Deny anonymous users

    owner? || authorized_employee?
  end

  def new?
    # Allow anyone to create orders (customers and staff)
    true
  end

  def create?
    # Allow anyone to create orders (customers and staff)
    true
  end

  def edit?
    owner? || employee_admin? || employee_manager?
  end

  def update?
    # Allow anonymous users to update orders in smartmenu context (adding items, etc.)
    return true if user.id.nil? # Allow anonymous customers (User.new has no ID)

    # Allow access for owners and employees
    owner? || authorized_employee?
  end

  def destroy?
    owner? || employee_admin?
  end

  def analytics?
    owner? || employee_admin?
  end

  def performance?
    owner? || employee_admin?
  end

  def bulk_update?
    owner? || employee_admin? || employee_manager?
  end

  class Scope < Scope
    def resolve
      # Include orders from restaurants owned by user
      owned_ids = scope.joins(:restaurant).where(restaurants: { user_id: user.id }).pluck(:id)
      
      # Include orders from restaurants where user is an employee
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
    return false unless user && record.respond_to?(:restaurant)

    record.restaurant&.user_id == user.id
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

    user.employees.exists?(restaurant_id: record.restaurant.id, role: [:manager, :admin], status: :active)
  end

end
