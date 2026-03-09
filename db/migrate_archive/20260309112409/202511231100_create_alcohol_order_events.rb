class CreateAlcoholOrderEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :alcohol_order_events do |t|
      t.references :ordr, null: false, foreign_key: true
      t.references :ordritem, null: false, foreign_key: true
      t.references :menuitem, null: false, foreign_key: true
      t.references :restaurant, null: false, foreign_key: true
      t.integer :employee_id, null: true
      t.string :customer_sessionid, null: true
      t.boolean :alcoholic, null: false, default: false
      t.decimal :abv, precision: 5, scale: 2
      t.string :alcohol_classification
      t.boolean :age_check_acknowledged, null: false, default: false
      t.datetime :acknowledged_at

      t.timestamps
    end
    add_index :alcohol_order_events, :employee_id
    add_index :alcohol_order_events, :customer_sessionid
  end
end
