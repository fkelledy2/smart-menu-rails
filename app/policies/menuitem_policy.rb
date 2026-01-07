class MenuitemPolicy < ApplicationPolicy
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
      scope.joins(menusection: { menu: :restaurant })
        .where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:menusection)

    menu = record.menusection&.menu
    owner_restaurant = menu&.owner_restaurant || menu&.restaurant
    owner_restaurant&.user_id == user.id
  end
end
