class AddBillRequestedAtToOrder < ActiveRecord::Migration[7.1]
  def change
    add_column :ordrs, :billRequestedAt, :datetime
  end
end
