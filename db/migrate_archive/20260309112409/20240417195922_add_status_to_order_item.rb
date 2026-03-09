class AddStatusToOrderItem < ActiveRecord::Migration[7.1]
  def change
    add_column :ordritems, :status, :integer, :default => 0
  end
end
