class OcrMenuItemPolicy < ApplicationPolicy
  def update?
    owner?
  end

  private

  def owner?
    return false unless user && record.respond_to?(:ocr_menu_section)

    section = record.ocr_menu_section
    import = section&.ocr_menu_import
    restaurant = import&.restaurant
    restaurant && restaurant.user_id == user.id
  end
end
