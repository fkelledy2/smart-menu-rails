class OcrMenuSectionPolicy < ApplicationPolicy
  def update?
    owner? || admin?
  end

  class Scope < Scope
    def resolve
      if admin?
        scope.all
      else
        # Limit to sections belonging to restaurants owned by the user
        scope.joins(ocr_menu_import: :restaurant).where(restaurants: { user_id: user.id })
      end
    end

    private

    def admin?
      user.respond_to?(:admin?) && user.admin?
    end
  end

  private

  def admin?
    user.respond_to?(:admin?) && user.admin?
  end

  def owner?
    return false unless user && record.respond_to?(:ocr_menu_import)

    restaurant = record.ocr_menu_import&.restaurant
    restaurant && restaurant.user_id == user.id
  end
end
