class AddQuantityToOrdritems < ActiveRecord::Migration[7.2]
  def change
    add_column :ordritems, :quantity, :integer, default: 1, null: false

    add_check_constraint :ordritems, "quantity > 0", name: "ordritems_quantity_positive"
    add_check_constraint :ordritems, "quantity <= 99", name: "ordritems_quantity_max"

    add_index :ordritems, [:ordr_id, :menuitem_id, :size_name, :status],
              name: "index_ordritems_on_merge_lookup"
  end
end
