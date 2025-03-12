class AddDisplayImagesInPopupToRestaurants < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :displayImagesInPopup, :boolean, :default => false
    add_column :menus, :displayImagesInPopup, :boolean, :default => false
  end
end
