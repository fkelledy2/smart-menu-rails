class AddArchivedToModels < ActiveRecord::Migration[7.1]
  def change
    add_column :allergyns, :archived, :boolean, default: false
    add_column :employees, :archived, :boolean, default: false
    add_column :ingredients, :archived, :boolean, default: false
    add_column :inventories, :archived, :boolean, default: false
    add_column :menus, :archived, :boolean, default: false
    add_column :menuavailabilities, :archived, :boolean, default: false
    add_column :menuitems, :archived, :boolean, default: false
    add_column :menusections, :archived, :boolean, default: false
    add_column :restaurants, :archived, :boolean, default: false
    add_column :restaurantavailabilities, :archived, :boolean, default: false
    add_column :sizes, :archived, :boolean, default: false
    add_column :tablesettings, :archived, :boolean, default: false
    add_column :tags, :archived, :boolean, default: false
    add_column :taxes, :archived, :boolean, default: false
    add_column :tips, :archived, :boolean, default: false
  end
end
