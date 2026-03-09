class AddAllowAlcoholToRestaurants < ActiveRecord::Migration[7.0]
  def change
    add_column :restaurants, :allow_alcohol, :boolean, default: false, null: false
  end
end
