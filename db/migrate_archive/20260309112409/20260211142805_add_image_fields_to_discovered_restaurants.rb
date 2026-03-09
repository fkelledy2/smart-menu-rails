class AddImageFieldsToDiscoveredRestaurants < ActiveRecord::Migration[7.2]
  def change
    add_column :discovered_restaurants, :image_context, :string
    add_column :discovered_restaurants, :image_style_profile, :text
  end
end
