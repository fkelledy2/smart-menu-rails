class OrdrPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    # Allow both staff (owners) and customers to view orders
    return true unless user # Allow anonymous customers
    owner?
  end

  def new?
    # Allow both staff and customers to create orders
    return true unless user # Allow anonymous customers
    user.present?
  end

  def create?
    # Allow both staff and customers to create orders
    return true unless user # Allow anonymous customers
    user.present?
  end

  def edit?
    owner?
  end

  def update?
    # Allow both staff (owners) and customers to update orders
    return true unless user # Allow anonymous customers
    owner?
  end

  def destroy?
    owner?
  end

  class Scope < Scope
    def resolve
      scope.joins(:restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:restaurant)
    record.restaurant&.user_id == user.id
  end
end
