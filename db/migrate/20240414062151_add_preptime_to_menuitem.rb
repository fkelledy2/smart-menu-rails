class AddPreptimeToMenuitem < ActiveRecord::Migration[7.1]
  def change
    add_column :menuitems, :preptime, :integer, :default => 0
  end
end
