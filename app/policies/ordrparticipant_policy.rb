# frozen_string_literal: true

class OrdrparticipantPolicy < ApplicationPolicy
  # Order participants are sensitive business data - only restaurant owners can access

  def index?
    user.present?
  end

  def show?
    user.present? && owns_order_participant?
  end

  def create?
    # Allow anonymous users to create participant records in smartmenu context
    return true if user.id.nil? # Allow anonymous customers (User.new has no ID)
    
    user.present?
  end

  def update?
    # Allow anonymous users to update their own participant information (name, etc.)
    return true if user.id.nil? # Allow anonymous customers (User.new has no ID)
    
    user.present? && owns_order_participant?
  end

  def destroy?
    user.present? && owns_order_participant?
  end

  class Scope < Scope
    def resolve
      if user.present?
        # Scope to order participants from restaurants owned by the user
        restaurant_ids = user.restaurants.pluck(:id)
        scope.joins(ordr: :restaurant).where(ordrs: { restaurant_id: restaurant_ids })
      else
        scope.none
      end
    end
  end

  private

  def owns_order_participant?
    return false unless user && record.ordr&.restaurant

    # Check if user owns the restaurant that the order belongs to
    user.restaurants.exists?(id: record.ordr.restaurant_id)
  end
end
