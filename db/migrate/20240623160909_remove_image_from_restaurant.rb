class RemoveImageFromRestaurant < ActiveRecord::Migration[7.1]
  def change
    remove_column :restaurants, :image
  end
end
