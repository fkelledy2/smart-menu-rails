class CreateOcrMenuItems < ActiveRecord::Migration[7.1]
  def change
    create_table :ocr_menu_items do |t|
      t.references :ocr_menu_section, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2
      t.text :allergens, array: true, default: []
      t.integer :sequence, null: false, default: 0
      t.boolean :is_confirmed, default: false
      t.boolean :is_vegetarian, default: false
      t.boolean :is_vegan, default: false
      t.boolean :is_gluten_free, default: false
      t.jsonb :metadata, default: {}
      t.string :page_reference
      # In this app, the base table is named 'menuitems' (singular model Menuitem)
      # not the conventional 'menu_items'. Point the FK to the correct table.
      t.references :menu_item, foreign_key: { to_table: :menuitems }

      t.timestamps
    end
    
    add_index :ocr_menu_items, :sequence
    add_index :ocr_menu_items, :is_confirmed
    add_index :ocr_menu_items, :is_vegetarian
    add_index :ocr_menu_items, :is_vegan
    add_index :ocr_menu_items, :is_gluten_free
    add_index :ocr_menu_items, :allergens, using: 'gin'
  end
end
