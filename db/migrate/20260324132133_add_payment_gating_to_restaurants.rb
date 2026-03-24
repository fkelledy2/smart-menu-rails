class AddPaymentGatingToRestaurants < ActiveRecord::Migration[7.2]
  def change
    add_column :restaurants, :payment_gating_enabled, :boolean, null: false, default: false
  end
end
