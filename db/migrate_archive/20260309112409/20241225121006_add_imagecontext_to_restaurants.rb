class AddImagecontextToRestaurants < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :imagecontext, :string
  end
end
