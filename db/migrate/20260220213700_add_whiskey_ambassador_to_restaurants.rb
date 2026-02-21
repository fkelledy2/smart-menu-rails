class AddWhiskeyAmbassadorToRestaurants < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :whiskey_ambassador_enabled, :boolean, default: false, null: false
    add_column :restaurants, :max_whiskey_flights, :integer, default: 5, null: false
  end
end
