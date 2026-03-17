class CreateMenuitemIngredientQuantities < ActiveRecord::Migration[7.2]
  def change
    create_table :menuitem_ingredient_quantities do |t|
      t.bigint :menuitem_id, null: false
      t.bigint :ingredient_id, null: false
      t.decimal :quantity, precision: 10, scale: 4, null: false
      t.string :unit, null: false
      t.decimal :cost_per_unit, precision: 10, scale: 4

      t.timestamps
    end

    add_index :menuitem_ingredient_quantities, [:menuitem_id, :ingredient_id], 
              name: 'idx_menuitem_ingredient'
    add_index :menuitem_ingredient_quantities, :menuitem_id
    add_index :menuitem_ingredient_quantities, :ingredient_id
    
    add_foreign_key :menuitem_ingredient_quantities, :menuitems, column: :menuitem_id, on_delete: :cascade
    add_foreign_key :menuitem_ingredient_quantities, :ingredients, column: :ingredient_id, on_delete: :cascade
  end
end
