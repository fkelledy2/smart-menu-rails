class RenameNotesToDescriptionInDiscoveredRestaurants < ActiveRecord::Migration[7.2]
  def change
    rename_column :discovered_restaurants, :notes, :description
  end
end
