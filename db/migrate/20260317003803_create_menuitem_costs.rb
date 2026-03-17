class CreateMenuitemCosts < ActiveRecord::Migration[7.2]
  def change
    create_table :menuitem_costs do |t|
      t.bigint :menuitem_id, null: false
      t.decimal :ingredient_cost, precision: 10, scale: 4, default: 0
      t.decimal :labor_cost, precision: 10, scale: 4, default: 0
      t.decimal :packaging_cost, precision: 10, scale: 4, default: 0
      t.decimal :overhead_cost, precision: 10, scale: 4, default: 0
      t.string :cost_source, default: 'manual'
      t.boolean :is_active, default: true
      t.date :effective_date, null: false
      t.text :notes
      t.bigint :created_by_user_id

      t.timestamps
    end

    add_index :menuitem_costs, [:menuitem_id, :is_active]
    add_index :menuitem_costs, :effective_date
    add_index :menuitem_costs, :created_by_user_id
    
    add_foreign_key :menuitem_costs, :menuitems, column: :menuitem_id, on_delete: :cascade
    add_foreign_key :menuitem_costs, :users, column: :created_by_user_id
  end
end
