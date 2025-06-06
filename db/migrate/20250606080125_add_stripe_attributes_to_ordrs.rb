class AddStripeAttributesToOrdrs < ActiveRecord::Migration[7.1]
  def change
     add_column :ordrs, :paymentlink, :string
     add_column :ordrs, :paymentstatus, :integer, default: 0
  end
end
