# frozen_string_literal: true

class RestaurantavailabilityPolicy < ApplicationPolicy
  # Restaurant availability settings are business-critical - only restaurant owners can manage

  def index?
    user.present?
  end

  def show?
    user.present? && owns_restaurant_availability?
  end

  def create?
    user.present?
  end

  def update?
    user.present? && owns_restaurant_availability?
  end

  def destroy?
    user.present? && owns_restaurant_availability?
  end

  class Scope < Scope
    def resolve
      if user.present?
        # Scope to restaurant availabilities from restaurants owned by the user
        restaurant_ids = user.restaurants.pluck(:id)
        scope.where(restaurant_id: restaurant_ids)
      else
        scope.none
      end
    end
  end

  private

  def owns_restaurant_availability?
    return false unless user && record.restaurant

    # Check if user owns the restaurant
    user.restaurants.exists?(id: record.restaurant_id)
  end
end
