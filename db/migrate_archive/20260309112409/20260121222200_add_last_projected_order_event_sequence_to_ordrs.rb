class AddLastProjectedOrderEventSequenceToOrdrs < ActiveRecord::Migration[7.2]
  def change
    add_column :ordrs, :last_projected_order_event_sequence, :bigint, null: false, default: 0
    add_index :ordrs, :last_projected_order_event_sequence
  end
end
