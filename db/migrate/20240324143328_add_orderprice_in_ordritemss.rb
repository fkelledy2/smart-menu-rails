class AddOrderpriceInOrdritemss < ActiveRecord::Migration[7.1]
  def change
    add_column :ordritems, :ordritemprice, :float, default: 0
  end
end
