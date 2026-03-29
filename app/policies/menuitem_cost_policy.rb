# frozen_string_literal: true

class MenuitemCostPolicy < ApplicationPolicy
  # Only the restaurant owner (and super admins) can manage ingredient cost data.
  # set_restaurant in the controller already scopes to current_user.restaurants,
  # so record-level checks here are a defence-in-depth guard.

  def new?
    create?
  end

  def create?
    return true if super_admin?

    owner?
  end

  def edit?
    update?
  end

  def update?
    return true if super_admin?

    owner?
  end

  def destroy?
    update?
  end

  class Scope < Scope
    def resolve
      return scope.all if user.super_admin?

      restaurant_ids = user.restaurants.select(:id)
      menu_ids = Menu.where(restaurant_id: restaurant_ids).select(:id)
      menuitem_ids = Menuitem.joins(:menusection).where(menusections: { menu_id: menu_ids }).select(:id)
      scope.where(menuitem_id: menuitem_ids)
    end
  end

  private

  def owner?
    return false unless record.is_a?(MenuitemCost) && record.menuitem_id.present?

    restaurant_ids = user.restaurants.pluck(:id)
    Menuitem.joins(:menusection => :menu)
            .where(id: record.menuitem_id)
            .where(menus: { restaurant_id: restaurant_ids })
            .exists?
  end
end
