class CreateProfitMarginTargets < ActiveRecord::Migration[7.2]
  def change
    create_table :profit_margin_targets do |t|
      t.bigint :restaurant_id
      t.bigint :menusection_id
      t.bigint :menuitem_id
      t.decimal :target_margin_percentage, precision: 5, scale: 2, null: false
      t.decimal :minimum_margin_percentage, precision: 5, scale: 2
      t.date :effective_from, null: false
      t.date :effective_to

      t.timestamps
    end

    add_index :profit_margin_targets, :restaurant_id
    add_index :profit_margin_targets, :menusection_id
    add_index :profit_margin_targets, :menuitem_id
    add_index :profit_margin_targets, [:effective_from, :effective_to], name: 'idx_effective_dates'
    
    add_foreign_key :profit_margin_targets, :restaurants, column: :restaurant_id, on_delete: :cascade
    add_foreign_key :profit_margin_targets, :menusections, column: :menusection_id, on_delete: :cascade
    add_foreign_key :profit_margin_targets, :menuitems, column: :menuitem_id, on_delete: :cascade
  end
end
