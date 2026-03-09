class AddPreferredEmailToDiscoveredRestaurants < ActiveRecord::Migration[7.2]
  def change
    add_column :discovered_restaurants, :preferred_email, :string
  end
end
