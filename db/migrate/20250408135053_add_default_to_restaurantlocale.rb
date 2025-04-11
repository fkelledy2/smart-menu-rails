class AddDefaultToRestaurantlocale < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurantlocales, :dfault, :boolean
  end
end
