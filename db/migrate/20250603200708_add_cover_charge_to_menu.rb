class AddCoverChargeToMenu < ActiveRecord::Migration[7.1]
  def change
     add_column :menus, :covercharge, :float, default: 0.0
 end
end
