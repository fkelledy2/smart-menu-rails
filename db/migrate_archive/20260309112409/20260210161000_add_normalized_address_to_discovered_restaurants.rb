class AddNormalizedAddressToDiscoveredRestaurants < ActiveRecord::Migration[7.2]
  def change
    add_column :discovered_restaurants, :address1, :string
    add_column :discovered_restaurants, :address2, :string
    add_column :discovered_restaurants, :city, :string
    add_column :discovered_restaurants, :state, :string
    add_column :discovered_restaurants, :postcode, :string
    add_column :discovered_restaurants, :country_code, :string
    add_column :discovered_restaurants, :currency, :string

    add_index :discovered_restaurants, :country_code
  end
end
