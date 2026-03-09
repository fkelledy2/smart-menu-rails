class DropAlcoholicFromMenuitems < ActiveRecord::Migration[7.2]
  def change
    remove_index :menuitems, :alcoholic, if_exists: true
    remove_column :menuitems, :alcoholic, :boolean, if_exists: true
  end
end
