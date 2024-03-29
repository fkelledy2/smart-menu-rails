class AddStatusToRestaurantsettings < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurantavailabilities, :status, :integer
    add_column :restaurantavailabilities, :sequence, :integer
  end
end
