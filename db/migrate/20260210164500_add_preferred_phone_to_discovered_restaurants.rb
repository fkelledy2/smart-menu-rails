class AddPreferredPhoneToDiscoveredRestaurants < ActiveRecord::Migration[7.2]
  def change
    add_column :discovered_restaurants, :preferred_phone, :string
  end
end
