class AddInventorySettingToRestaurantAndMenu < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :inventoryTracking, :boolean, :default => false
    add_column :menus, :inventoryTracking, :boolean, :default => false
  end
end
