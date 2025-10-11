# frozen_string_literal: true

class MenuavailabilityPolicy < ApplicationPolicy
  # Menu availability settings are business-critical - only restaurant owners can manage

  def index?
    user.present?
  end

  def show?
    user.present? && owns_menu_availability?
  end

  def create?
    user.present?
  end

  def update?
    user.present? && owns_menu_availability?
  end

  def destroy?
    user.present? && owns_menu_availability?
  end

  class Scope < Scope
    def resolve
      if user.present?
        # Scope to menu availabilities from restaurants owned by the user
        restaurant_ids = user.restaurants.pluck(:id)
        scope.joins(menu: :restaurant).where(menus: { restaurant_id: restaurant_ids })
      else
        scope.none
      end
    end
  end

  private

  def owns_menu_availability?
    return false unless user && record.menu&.restaurant

    # Check if user owns the restaurant that the menu belongs to
    user.restaurants.exists?(id: record.menu.restaurant_id)
  end
end
