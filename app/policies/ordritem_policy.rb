class OrdritemPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    # Allow both staff and customers to view order items
    return true unless user # Allow anonymous customers
    owner?
  end

  def new?
    # Allow both staff and customers to create order items
    return true unless user # Allow anonymous customers
    user.present?
  end

  def create?
    # Allow both staff and customers to create order items
    return true unless user # Allow anonymous customers
    user.present?
  end

  def edit?
    # Allow both staff and customers to edit order items
    return true unless user # Allow anonymous customers
    owner?
  end

  def update?
    # Allow both staff and customers to update order items
    return true unless user # Allow anonymous customers
    owner?
  end

  def destroy?
    # Allow both staff and customers to delete order items
    return true unless user # Allow anonymous customers
    owner?
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
