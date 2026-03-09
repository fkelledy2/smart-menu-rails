class AddScheduleToMenusection < ActiveRecord::Migration[7.1]
  def change
    add_column :menusections, :fromhour, :integer, :default => 0
    add_column :menusections, :frommin, :integer, :default => 0
    add_column :menusections, :tohour, :integer, :default => 23
    add_column :menusections, :tomin, :integer, :default => 59
    add_column :menusections, :restricted, :boolean, :default => false
  end
end
