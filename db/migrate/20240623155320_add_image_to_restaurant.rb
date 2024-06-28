class AddImageToRestaurant < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :image_data, :text
  end
end
