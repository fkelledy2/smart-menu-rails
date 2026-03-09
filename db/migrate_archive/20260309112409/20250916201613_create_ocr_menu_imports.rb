class CreateOcrMenuImports < ActiveRecord::Migration[7.1]
  def change
    create_table :ocr_menu_imports do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.string :name, null: false
      t.string :status, null: false, default: 'pending'
      t.text :error_message
      t.integer :total_pages
      t.integer :processed_pages, default: 0
      t.jsonb :metadata, default: {}
      t.references :menu, foreign_key: { to_table: :menus }
      t.datetime :completed_at
      t.datetime :failed_at

      t.timestamps
    end
    
    add_index :ocr_menu_imports, :status
  end
end
