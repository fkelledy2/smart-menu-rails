class MenuitemIngredientMapping < ApplicationRecord
  belongs_to :menuitem
  belongs_to :ingredient
end
