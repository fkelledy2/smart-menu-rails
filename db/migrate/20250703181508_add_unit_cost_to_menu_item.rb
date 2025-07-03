class AddUnitCostToMenuItem < ActiveRecord::Migration[7.1]
  def change
     add_column :menuitems, :unitcost, :float, default: 0
  end
end
