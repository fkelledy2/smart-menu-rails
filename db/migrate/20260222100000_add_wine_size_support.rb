class AddWineSizeSupport < ActiveRecord::Migration[7.1]
  def change
    # Add category to sizes so wine-specific sizes can be distinguished
    add_column :sizes, :category, :string, default: 'general', null: false
    add_index :sizes, [:restaurant_id, :category]

    # Track which size was ordered on each line item
    add_column :ordritems, :size_name, :string
  end
end
