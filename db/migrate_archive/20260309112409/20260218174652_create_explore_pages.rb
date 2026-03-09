class CreateExplorePages < ActiveRecord::Migration[7.2]
  def change
    create_table :explore_pages do |t|
      t.string :country_slug, null: false
      t.string :country_name, null: false
      t.string :city_slug, null: false
      t.string :city_name, null: false
      t.string :category_slug
      t.string :category_name
      t.integer :restaurant_count, default: 0, null: false
      t.text :meta_title
      t.text :meta_description
      t.datetime :last_refreshed_at
      t.boolean :published, default: false, null: false

      t.timestamps
    end

    add_index :explore_pages, [:country_slug, :city_slug, :category_slug],
              unique: true, name: 'idx_explore_pages_unique_path'
    add_index :explore_pages, :published
    add_index :explore_pages, :restaurant_count
  end
end
