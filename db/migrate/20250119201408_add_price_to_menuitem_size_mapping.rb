class AddPriceToMenuitemSizeMapping < ActiveRecord::Migration[7.1]
  def change
    add_column :menuitem_size_mappings, :price, :float, default: 0.0
  end
end
