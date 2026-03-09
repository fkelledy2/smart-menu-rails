class AddTastingMenuFields < ActiveRecord::Migration[7.0]
  def change
    change_table :menusections, bulk: true do |t|
      t.boolean :tasting_menu, default: false, null: false
      t.integer :tasting_price_cents
      t.string  :tasting_currency
      t.string  :price_per, default: 'person' # 'person' or 'table'
      t.integer :min_party_size
      t.integer :max_party_size
      t.text    :includes_description
      t.boolean :allow_substitutions, default: false, null: false
      t.boolean :allow_pairing, default: false, null: false
      t.integer :pairing_price_cents
      t.string  :pairing_currency
    end

    change_table :menuitems, bulk: true do |t|
      t.boolean :tasting_optional, default: false, null: false
      t.integer :tasting_supplement_cents
      t.string  :tasting_supplement_currency
      t.integer :course_order
    end

    add_index :menusections, :tasting_menu
    add_index :menuitems, :course_order
  end
end
