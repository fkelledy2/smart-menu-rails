class CreateWhiskeyFlights < ActiveRecord::Migration[7.1]
  def change
    create_table :whiskey_flights do |t|
      t.references :menu, null: false, foreign_key: true
      t.string     :theme_key, null: false
      t.string     :title, null: false
      t.text       :narrative
      t.jsonb      :items, null: false, default: []
      t.string     :source, default: 'ai', null: false
      t.string     :status, default: 'draft', null: false
      t.float      :total_price
      t.float      :custom_price
      t.datetime   :generated_at
      t.timestamps
    end

    add_index :whiskey_flights, [:menu_id, :theme_key], unique: true
    add_index :whiskey_flights, :status
  end
end
