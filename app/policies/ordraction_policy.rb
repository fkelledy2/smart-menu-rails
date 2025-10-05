# frozen_string_literal: true

class OrdractionPolicy < ApplicationPolicy
  # Order actions are sensitive - only authenticated users can access
  # and should be scoped to their own restaurant's orders
  
  def index?
    user.present?
  end
  
  def show?
    user.present? && owns_order_action?
  end
  
  def create?
    user.present?
  end
  
  def update?
    user.present? && owns_order_action?
  end
  
  def destroy?
    user.present? && owns_order_action?
  end
  
  class Scope < Scope
    def resolve
      if user.present?
        # Scope to order actions from restaurants owned by the user
        restaurant_ids = user.restaurants.pluck(:id)
        scope.joins(ordr: :restaurant).where(ordrs: { restaurant_id: restaurant_ids })
      else
        scope.none
      end
    end
  end
  
  private
  
  def owns_order_action?
    return false unless user && record.ordr
    
    # Check if user owns the restaurant that the order belongs to
    user.restaurants.exists?(id: record.ordr.restaurant_id)
  end
end
