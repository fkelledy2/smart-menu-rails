class CreateMenuitemIngredientMappings < ActiveRecord::Migration[7.1]
  def change
    create_table :menuitem_ingredient_mappings do |t|
      t.references :menuitem, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true

      t.timestamps
    end
  end
end
