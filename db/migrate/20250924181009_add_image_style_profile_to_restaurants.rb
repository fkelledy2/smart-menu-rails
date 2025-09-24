class AddImageStyleProfileToRestaurants < ActiveRecord::Migration[6.1]
  def change
    add_column :restaurants, :image_style_profile, :text
  end
end
