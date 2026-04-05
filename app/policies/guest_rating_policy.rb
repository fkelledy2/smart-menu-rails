# frozen_string_literal: true

class GuestRatingPolicy < ApplicationPolicy
  # Guests (unauthenticated) can create ratings for their own order.
  # No authentication required — the ordr_id/sessionid pairing is the gate.
  def create?
    true
  end

  # Restaurant owners/managers can view their restaurant's ratings.
  def index?
    return true if super_admin?

    owner_or_manager?
  end

  def show?
    return true if super_admin?

    owner_or_manager?
  end

  class Scope < Scope
    def resolve
      return scope.all if user.respond_to?(:super_admin?) && user.super_admin?

      scope.joins(:restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner_or_manager?
    return false unless user&.persisted?

    restaurant = record.respond_to?(:restaurant) ? record.restaurant : record
    return false unless restaurant.is_a?(Restaurant)

    restaurant.user_id == user.id ||
      user.employees.exists?(restaurant_id: restaurant.id, role: %w[manager admin])
  end
end
