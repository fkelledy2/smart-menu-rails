class AddImageDateToMenus < ActiveRecord::Migration[7.1]
  def change
    add_column :menus, :image_data, :text
    add_column :menusections, :image_data, :text
    add_column :menuitems, :image_data, :text
    remove_column :restaurants, :image
    remove_column :menus, :image
    remove_column :menuitems, :image
  end
end
