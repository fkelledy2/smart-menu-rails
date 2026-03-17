class ProfitMarginTargetPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.super_admin?
        scope.all
      else
        restaurant_ids = user.restaurants.pluck(:id)
        scope.where(restaurant_id: restaurant_ids)
      end
    end
  end

  def index?
    true
  end

  def create?
    user.present?
  end

  def update?
    user.super_admin? || record.restaurant_id.in?(user.restaurants.pluck(:id))
  end

  def destroy?
    update?
  end
end
