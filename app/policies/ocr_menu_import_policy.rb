class OcrMenuImportPolicy < ApplicationPolicy
  def show? = owner?
  def edit? = owner?
  def update? = owner?
  def destroy? = owner?
  def process_pdf? = owner?
  def confirm_import? = owner?
  def polish? = owner?
  def polish_progress? = owner?
  def reorder_sections? = owner?
  def reorder_items? = owner?
  def toggle_section_confirmation? = owner?
  def toggle_all_confirmation? = owner?

  class Scope < Scope
    def resolve
      scope.joins(:restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:restaurant) && record.restaurant

    record.restaurant.user_id == user.id
  end
end
