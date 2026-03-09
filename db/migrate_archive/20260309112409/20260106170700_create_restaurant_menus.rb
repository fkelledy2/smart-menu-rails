class CreateRestaurantMenus < ActiveRecord::Migration[7.0]
  def change
    create_table :restaurant_menus do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.references :menu, null: false, foreign_key: true

      t.integer :sequence
      t.integer :status, null: false, default: 1

      t.boolean :availability_override_enabled, null: false, default: false
      t.integer :availability_state, null: false, default: 0

      t.timestamps
    end

    add_index :restaurant_menus, %i[restaurant_id menu_id], unique: true
  end
end
