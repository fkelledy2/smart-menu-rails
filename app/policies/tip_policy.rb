# frozen_string_literal: true

class TipPolicy < ApplicationPolicy
  # Tips are business-critical financial data - only restaurant owners can manage

  def index?
    user.present?
  end

  def show?
    user.present? && owns_tip?
  end

  def create?
    user.present?
  end

  def update?
    user.present? && owns_tip?
  end

  def destroy?
    user.present? && owns_tip?
  end

  class Scope < Scope
    def resolve
      if user.present?
        # Scope to tips from restaurants owned by the user
        restaurant_ids = user.restaurants.pluck(:id)
        scope.where(restaurant_id: restaurant_ids)
      else
        scope.none
      end
    end
  end

  private

  def owns_tip?
    return false unless user && record && record.restaurant

    # Check if user owns the restaurant
    user.restaurants.exists?(id: record.restaurant_id)
  end
end
