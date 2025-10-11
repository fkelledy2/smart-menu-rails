# frozen_string_literal: true

class OrdritemnotePolicy < ApplicationPolicy
  # Order item notes are sensitive business data - only restaurant owners can access

  def index?
    user.present?
  end

  def show?
    user.present? && owns_order_item_note?
  end

  def create?
    user.present?
  end

  def update?
    user.present? && owns_order_item_note?
  end

  def destroy?
    user.present? && owns_order_item_note?
  end

  class Scope < Scope
    def resolve
      if user.present?
        # Scope to order item notes from restaurants owned by the user
        restaurant_ids = user.restaurants.pluck(:id)
        scope.joins(ordritem: { ordr: :restaurant })
          .where(ordritems: { ordrs: { restaurant_id: restaurant_ids } })
      else
        scope.none
      end
    end
  end

  private

  def owns_order_item_note?
    return false unless user && record.ordritem&.ordr&.restaurant

    # Check if user owns the restaurant that the order belongs to
    user.restaurants.exists?(id: record.ordritem.ordr.restaurant_id)
  end
end
