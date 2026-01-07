# frozen_string_literal: true

class MenusectionlocalePolicy < ApplicationPolicy
  # Menu section locales are business data - only restaurant owners can manage

  def index?
    user.present?
  end

  def show?
    user.present? && owns_menusection_locale?
  end

  def create?
    user.present?
  end

  def update?
    user.present? && owns_menusection_locale?
  end

  def destroy?
    user.present? && owns_menusection_locale?
  end

  class Scope < Scope
    def resolve
      if user.present?
        # Scope to menu section locales from restaurants owned by the user
        restaurant_ids = user.restaurants.pluck(:id)
        scope.joins(menusection: { menu: :restaurant })
          .where(menusections: { menus: { restaurant_id: restaurant_ids } })
      else
        scope.none
      end
    end
  end

  private

  def owns_menusection_locale?
    return false unless user && record.menusection&.menu

    menu = record.menusection.menu
    owner_restaurant = menu.owner_restaurant || menu.restaurant
    return false unless owner_restaurant

    # Check if user owns the owner restaurant that controls this menu
    user.restaurants.exists?(id: owner_restaurant.id)
  end
end
