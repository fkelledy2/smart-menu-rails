class CreateDiscoveredRestaurants < ActiveRecord::Migration[7.2]
  def change
    create_table :discovered_restaurants do |t|
      t.string :city_name, null: false
      t.string :city_place_id

      t.string :google_place_id, null: false
      t.string :name, null: false
      t.string :website_url

      t.integer :status, null: false, default: 0
      t.decimal :confidence_score, precision: 5, scale: 4

      t.datetime :discovered_at
      t.text :notes
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :discovered_restaurants, :google_place_id, unique: true
    add_index :discovered_restaurants, %i[city_name status discovered_at]
  end
end
