class InventoryPolicy < ApplicationPolicy
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
      scope.joins(menuitem: { menusection: { menu: :restaurant } })
        .where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:menuitem)

    record.menuitem&.menusection&.menu&.restaurant&.user_id == user.id
  end
end
