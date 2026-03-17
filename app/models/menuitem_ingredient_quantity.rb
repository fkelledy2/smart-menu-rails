class MenuitemIngredientQuantity < ApplicationRecord
  belongs_to :menuitem
  belongs_to :ingredient

  validates :quantity, :unit, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :cost_per_unit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Calculate total cost for this ingredient in the recipe
  def total_cost
    return 0 unless quantity && cost_per_unit
    quantity * cost_per_unit
  end

  # Sync cost_per_unit from ingredient when created/updated
  before_save :sync_cost_from_ingredient, if: -> { cost_per_unit.nil? && ingredient.present? }

  private

  def sync_cost_from_ingredient
    self.cost_per_unit = ingredient.current_cost_per_unit if ingredient.current_cost_per_unit.present?
  end
end
