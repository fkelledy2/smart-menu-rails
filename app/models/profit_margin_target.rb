class ProfitMarginTarget < ApplicationRecord
  belongs_to :restaurant, optional: true
  belongs_to :menusection, optional: true
  belongs_to :menuitem, optional: true

  validates :target_margin_percentage, presence: true,
                                       numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :minimum_margin_percentage,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
  validates :effective_from, presence: true

  validate :exactly_one_target_level

  scope :active, lambda {
    where('effective_from <= ? AND (effective_to IS NULL OR effective_to >= ?)',
          Date.current, Date.current,)
  }
  scope :for_restaurant, ->(restaurant_id) { where(restaurant_id: restaurant_id) }
  scope :for_menuitem, ->(menuitem_id) { where(menuitem_id: menuitem_id) }

  private

  def exactly_one_target_level
    count = [restaurant_id, menusection_id, menuitem_id].compact.size
    if count != 1
      errors.add(:base, 'Must specify exactly one of: restaurant, menusection, or menuitem')
    end
  end
end
