class Ingredient < ApplicationRecord
  include IdentityCache

  # Associations
  belongs_to :restaurant, optional: true
  belongs_to :parent_ingredient, class_name: 'Ingredient', optional: true
  has_many :child_ingredients, class_name: 'Ingredient', foreign_key: 'parent_ingredient_id', dependent: :nullify
  has_many :menuitem_ingredient_mappings, dependent: :destroy
  has_many :menuitems, through: :menuitem_ingredient_mappings
  has_many :menuitem_ingredient_quantities, dependent: :destroy

  # IdentityCache configuration
  cache_index :id
  cache_index :name
  cache_index :archived
  cache_index :restaurant_id
  cache_index :is_shared

  # Cache associations
  cache_has_many :menuitem_ingredient_mappings, embed: :ids
  cache_belongs_to :restaurant

  # Validations
  validates :name, presence: true
  validates :current_cost_per_unit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :shared, -> { where(is_shared: true, restaurant_id: nil) }
  scope :for_restaurant, ->(restaurant_id) { where(restaurant_id: restaurant_id) }
  scope :active, -> { where(archived: false) }

  # Get effective cost (use override if exists, otherwise parent)
  def effective_cost_per_unit
    current_cost_per_unit || parent_ingredient&.current_cost_per_unit || 0
  end

  # Check if this is a restaurant-specific override
  def override?
    parent_ingredient_id.present?
  end

  # Get all menuitems using this ingredient
  def affected_menuitems
    menuitem_ingredient_quantities.includes(:menuitem).map(&:menuitem).uniq
  end
end
