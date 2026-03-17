class MenuitemCost < ApplicationRecord
  belongs_to :menuitem
  belongs_to :created_by_user, class_name: 'User', optional: true

  validates :ingredient_cost, :labor_cost, :packaging_cost, :overhead_cost, 
            numericality: { greater_than_or_equal_to: 0 }
  validates :effective_date, presence: true
  validates :cost_source, inclusion: { in: %w[manual recipe_calculated ai_estimated] }

  scope :active, -> { where(is_active: true) }
  scope :for_date, ->(date) { where('effective_date <= ?', date).order(effective_date: :desc) }

  # Calculate total cost
  def total_cost
    (ingredient_cost || 0) + (labor_cost || 0) + (packaging_cost || 0) + (overhead_cost || 0)
  end

  # Deactivate other costs when this one becomes active
  after_save :deactivate_other_costs, if: :is_active?

  private

  def deactivate_other_costs
    MenuitemCost.where(menuitem_id: menuitem_id, is_active: true)
                .where.not(id: id)
                .update_all(is_active: false)
  end
end
