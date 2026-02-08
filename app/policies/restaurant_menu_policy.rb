class RestaurantMenuPolicy < ApplicationPolicy
  def reorder?
    update?
  end

  def bulk_update?
    update?
  end

  def bulk_availability?
    update?
  end

  def availability?
    update?
  end

  def update?
    restaurant_owner?
  end

  def attach?
    restaurant_owner? && menu_owner?
  end

  def detach?
    restaurant_owner? && menu_owner?
  end

  class Scope < Scope
    def resolve
      return scope.none if user.blank?

      scope.joins(:restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def restaurant_owner?
    return false unless user && record.respond_to?(:restaurant) && record.restaurant

    record.restaurant.user_id == user.id
  end

  def menu_owner?
    menu = if record.respond_to?(:menu)
             record.menu
           elsif record.is_a?(Menu)
             record
           end

    return false unless user && menu

    owner_restaurant = menu.owner_restaurant || menu.restaurant
    owner_restaurant&.user_id == user.id
  end
end
