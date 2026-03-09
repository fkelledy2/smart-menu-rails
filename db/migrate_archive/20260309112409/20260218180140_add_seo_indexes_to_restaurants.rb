class AddSeoIndexesToRestaurants < ActiveRecord::Migration[7.2]
  def change
    add_index :restaurants, [:city, :country, :preview_enabled],
              name: 'idx_restaurants_geo_preview'
    add_index :restaurants, [:preview_enabled, :claim_status],
              name: 'idx_restaurants_preview_claim'
  end
end
