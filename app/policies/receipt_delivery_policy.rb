class ReceiptDeliveryPolicy < ApplicationPolicy
  # Staff, managers, and restaurant owners can create receipt deliveries.
  # Super-admins can do everything via the ApplicationPolicy default.
  def create?
    return true if super_admin?

    owner? || authorized_employee?
  end

  # Staff, managers, and owners can view the list for their restaurant.
  def index?
    return true if super_admin?

    owner? || authorized_employee?
  end

  def show?
    return true if super_admin?

    owner? || authorized_employee?
  end

  # Self-service: the action is permitted for anyone (including guests).
  # Rate-limiting is enforced at the Rack level via RackAttack.
  def self_service?
    true
  end

  class Scope < Scope
    def resolve
      return scope.all if user.respond_to?(:super_admin?) && user.super_admin?

      # Include deliveries for restaurants owned by the user
      owned_ids = scope
        .joins(:restaurant)
        .where(restaurants: { user_id: user.id })
        .pluck(:id)

      # Include deliveries for restaurants where user is an active employee
      employee_ids = scope
        .joins(restaurant: :employees)
        .where(employees: { user: user, status: :active })
        .pluck(:id)

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

    user.active_employee_for_restaurant?(record.restaurant.id)
  end
end
