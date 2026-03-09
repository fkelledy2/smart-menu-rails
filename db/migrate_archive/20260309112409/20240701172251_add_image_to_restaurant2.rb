class AddImageToRestaurant2 < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :image, :text
  end
end
