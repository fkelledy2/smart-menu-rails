class AddOrderingSettingToMenuAndRestaurant < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :allowOrdering, :boolean, :default => false
    add_column :menus, :allowOrdering, :boolean, :default => false
  end
end
