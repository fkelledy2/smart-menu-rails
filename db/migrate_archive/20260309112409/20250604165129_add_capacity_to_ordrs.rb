class AddCapacityToOrdrs < ActiveRecord::Migration[7.1]
  def change
     add_column :ordrs, :ordercapacity, :integer, default: 0
     add_column :ordrs, :covercharge, :float, default: 0.0
  end
end
