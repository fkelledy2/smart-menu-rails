class AddDefaultStationToMenuitemsAndMenusections < ActiveRecord::Migration[7.2]
  def change
    add_column :menuitems, :default_station, :integer
    add_column :menusections, :default_station, :integer
  end
end
