class AddRestaurantRefToAllergyns < ActiveRecord::Migration[7.1]
  def change
    add_reference :allergyns, :restaurant, null: true, foreign_key: true
    reversible do |change|
      change.up do
        firstRestaurant = Restaurant.first
        Allergyn.find_each do |item|
          item.restaurant_id = firstRestaurant
          item.save
        end
      end
    end
  end
end
