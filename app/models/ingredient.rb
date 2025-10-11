class Ingredient < ApplicationRecord
  include IdentityCache

  # Associations
  has_many :menuitem_ingredient_mappings, dependent: :destroy
  has_many :menuitems, through: :menuitem_ingredient_mappings

  # IdentityCache configuration
  cache_index :id
  cache_index :name
  cache_index :archived

  # Cache associations
  cache_has_many :menuitem_ingredient_mappings, embed: :ids

  # Validations
  validates :name, presence: true
end
