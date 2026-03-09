class AddEstablishmentTypesToRestaurantsAndDiscoveredRestaurants < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :establishment_types, :string, array: true, default: [], null: false
    add_column :discovered_restaurants, :establishment_types, :string, array: true, default: [], null: false
  end
end
