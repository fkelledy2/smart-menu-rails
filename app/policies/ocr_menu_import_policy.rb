class OcrMenuImportPolicy < ApplicationPolicy
  def show?; owner?; end
  def edit?; owner?; end
  def update?; owner?; end
  def destroy?; owner?; end
  def process_pdf?; owner?; end
  def confirm_import?; owner?; end
  def reorder_sections?; owner?; end
  def reorder_items?; owner?; end
  def toggle_section_confirmation?; owner?; end
  def toggle_all_confirmation?; owner?; end

  class Scope < Scope
    def resolve
      scope.joins(:restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:restaurant)
    record.restaurant.user_id == user.id
  end
end
