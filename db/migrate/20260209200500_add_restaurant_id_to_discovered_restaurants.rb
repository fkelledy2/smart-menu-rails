class AddRestaurantIdToDiscoveredRestaurants < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:discovered_restaurants, :restaurant_id)
      add_reference :discovered_restaurants, :restaurant, null: true, foreign_key: true
    end

    unless foreign_key_exists?(:discovered_restaurants, :restaurants)
      add_foreign_key :discovered_restaurants, :restaurants, column: :restaurant_id
    end

    unless index_exists?(:discovered_restaurants, :restaurant_id)
      add_index :discovered_restaurants, :restaurant_id
    end
  end
end
