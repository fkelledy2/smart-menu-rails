# frozen_string_literal: true

class MenuitemSizeMappingPolicy < ApplicationPolicy
  # Menu item size mappings are business data - only restaurant owners can manage
  
  def update?
    user.present? && owns_menuitem_size_mapping?
  end
  
  class Scope < Scope
    def resolve
      if user.present?
        # Scope to size mappings from restaurants owned by the user
        restaurant_ids = user.restaurants.pluck(:id)
        scope.joins(menuitem: { menusection: { menu: :restaurant } })
             .where(menuitems: { menusections: { menus: { restaurant_id: restaurant_ids } } })
      else
        scope.none
      end
    end
  end
  
  private
  
  def owns_menuitem_size_mapping?
    return false unless user && record.menuitem&.menusection&.menu&.restaurant
    
    # Check if user owns the restaurant that the menuitem belongs to
    user.restaurants.exists?(id: record.menuitem.menusection.menu.restaurant_id)
  end
end
