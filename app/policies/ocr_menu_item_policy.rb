class OcrMenuItemPolicy < ApplicationPolicy
  def update?
    result = owner?
    if Rails.env.test?
      Rails.logger.warn "[TEST DEBUG] OcrMenuItemPolicy#update?: user.id=#{user&.id}, result=#{result}"
    end
    result
  end

  private

  def owner?
    return false unless user && record.respond_to?(:ocr_menu_section)
    section = record.ocr_menu_section
    import = section&.ocr_menu_import
    restaurant = import&.restaurant
    is_owner = restaurant && restaurant.user_id == user.id
    if Rails.env.test?
      Rails.logger.warn "[TEST DEBUG] OcrMenuItemPolicy#owner?: user.id=#{user&.id}, restaurant.user_id=#{restaurant&.user_id}, is_owner=#{is_owner}"
    end
    is_owner
  end
end
