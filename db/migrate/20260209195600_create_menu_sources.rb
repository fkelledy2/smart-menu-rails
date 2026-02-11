class CreateMenuSources < ActiveRecord::Migration[7.2]
  def change
    create_table :menu_sources do |t|
      t.references :restaurant, null: true, foreign_key: true
      t.references :discovered_restaurant, null: true, foreign_key: true

      t.string :source_url, null: false
      t.integer :source_type, null: false, default: 0

      t.datetime :last_checked_at
      t.string :last_fingerprint
      t.string :etag
      t.datetime :last_modified

      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :menu_sources, :source_url
    add_index :menu_sources, %i[restaurant_id status]
    add_index :menu_sources, %i[discovered_restaurant_id status]
  end
end
