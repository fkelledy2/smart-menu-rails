class AddTimezoneToRestaurants < ActiveRecord::Migration[7.2]
  def change
    add_column :restaurants, :timezone, :string, default: 'UTC'
  end
end
