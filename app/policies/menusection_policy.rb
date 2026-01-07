class MenusectionPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    owner?
  end

  def create?
    user.present?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  class Scope < Scope
    def resolve
      scope.joins(menu: :restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:menu)

    owner_restaurant = record.menu&.owner_restaurant || record.menu&.restaurant
    owner_restaurant&.user_id == user.id
  end
end
