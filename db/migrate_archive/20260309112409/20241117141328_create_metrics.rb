class CreateMetrics < ActiveRecord::Migration[7.1]
  def change
    create_table :metrics do |t|
      t.integer :numberOfRestaurants
      t.integer :numberOfMenus
      t.integer :numberOfMenuItems
      t.integer :numberOfOrders
      t.float :totalOrderValue

      t.timestamps
    end
  end
end
