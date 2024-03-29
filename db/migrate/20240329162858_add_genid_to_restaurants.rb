class AddGenidToRestaurants < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :genid, :string
  end
end
