class AddGrowthEngineFieldsToRestaurants < ActiveRecord::Migration[7.2]
  def change
    add_column :restaurants, :google_place_id, :string

    add_column :restaurants, :claim_status, :integer, default: 0, null: false

    add_column :restaurants, :preview_enabled, :boolean, default: false, null: false
    add_column :restaurants, :preview_published_at, :datetime
    add_column :restaurants, :preview_indexable, :boolean, default: false, null: false

    add_index :restaurants, :google_place_id, unique: true
    add_index :restaurants, :claim_status
    add_index :restaurants, :preview_published_at
  end
end
