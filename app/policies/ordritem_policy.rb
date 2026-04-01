class OrdritemPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    # Allow both staff and customers to view order items
    return true unless user.persisted? # Allow anonymous customers

    owner?
  end

  def new?
    # Allow both staff and customers to create order items
    return true unless user.persisted? # Allow anonymous customers

    user.persisted?
  end

  def create?
    # Allow both staff and customers to create order items
    return true unless user.persisted? # Allow anonymous customers

    user.persisted?
  end

  def edit?
    # Allow both staff and customers to edit order items
    return true unless user.persisted? # Allow anonymous customers

    owner?
  end

  def update?
    # Allow both staff and customers to update order items
    return true unless user.persisted? # Allow anonymous customers

    owner?
  end

  def destroy?
    # Allow both staff and customers to delete order items
    return true unless user.persisted? # Allow anonymous customers

    owner?
  end

  def transition_fulfillment_status?
    return false unless user&.persisted?

    # Restaurant owner always permitted
    return true if record.ordr&.restaurant&.user_id == user.id

    # Active employee with manager or admin role
    return false unless record.ordr&.restaurant_id

    employee = user.employees.find_by(
      restaurant_id: record.ordr.restaurant_id,
      status: :active,
    )
    employee&.manager? || employee&.admin?
  end

  class Scope < Scope
    def resolve
      scope.joins(ordr: :restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:ordr)

    record.ordr&.restaurant&.user_id == user.id
  end
end
