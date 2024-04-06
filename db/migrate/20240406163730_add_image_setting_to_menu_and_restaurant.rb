class AddImageSettingToMenuAndRestaurant < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :displayImages, :boolean, :default => false
    add_column :menus, :displayImages, :boolean, :default => false
  end
end
