class IngredientPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.super_admin?
        scope.all
      else
        scope.joins(:restaurant).where(restaurants: { id: user.restaurants.pluck(:id) })
          .or(scope.where(is_shared: true, restaurant_id: nil))
      end
    end
  end

  def index?
    true
  end

  def show?
    user.super_admin? || record.restaurant_id.in?(user.restaurants.pluck(:id)) || record.is_shared?
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
