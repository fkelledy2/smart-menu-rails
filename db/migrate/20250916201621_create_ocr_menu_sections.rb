class CreateOcrMenuSections < ActiveRecord::Migration[7.1]
  def change
    create_table :ocr_menu_sections do |t|
      t.references :ocr_menu_import, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :sequence, null: false, default: 0
      t.jsonb :metadata, default: {}
      t.boolean :is_confirmed, default: false
      t.string :page_reference
      # In this app, the base table is named 'menusections' (singular model Menusection)
      # not the conventional 'menu_sections'. Point the FK to the correct table.
      t.references :menu_section, foreign_key: { to_table: :menusections }

      t.timestamps
    end
    
    add_index :ocr_menu_sections, :sequence
    add_index :ocr_menu_sections, :is_confirmed
  end
end
