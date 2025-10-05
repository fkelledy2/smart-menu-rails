class MenuitemIngredientMapping < ApplicationRecord
  include IdentityCache
  
  belongs_to :menuitem
  belongs_to :ingredient
  
  # IdentityCache configuration
  cache_index :id
  cache_index :menuitem_id
  cache_index :ingredient_id
  cache_index :menuitem_id, :ingredient_id, unique: true
  
  # Cache associations
  cache_belongs_to :menuitem
  cache_belongs_to :ingredient
  
  # Validations
  validates :menuitem_id, presence: true
  validates :ingredient_id, presence: true
  validates :menuitem_id, uniqueness: { scope: :ingredient_id }
end
