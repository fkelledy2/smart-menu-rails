class ExtendIngredientsForProfitTracking < ActiveRecord::Migration[7.2]
  def change
    add_column :ingredients, :restaurant_id, :bigint
    add_column :ingredients, :parent_ingredient_id, :bigint
    add_column :ingredients, :unit_of_measure, :string
    add_column :ingredients, :current_cost_per_unit, :decimal, precision: 10, scale: 4
    add_column :ingredients, :supplier_id, :bigint
    add_column :ingredients, :category, :string
    add_column :ingredients, :is_shared, :boolean, default: false
    
    add_index :ingredients, :restaurant_id
    add_index :ingredients, :parent_ingredient_id
    add_index :ingredients, :category
    add_index :ingredients, :is_shared
    
    add_foreign_key :ingredients, :restaurants, column: :restaurant_id
    add_foreign_key :ingredients, :ingredients, column: :parent_ingredient_id
  end
end
