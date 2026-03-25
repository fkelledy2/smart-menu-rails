class AddAutoPayToOrdrs < ActiveRecord::Migration[7.2]
  def change
    add_column :ordrs, :payment_on_file, :boolean, default: false, null: false
    add_column :ordrs, :payment_method_ref, :string
    add_column :ordrs, :payment_provider, :string
    add_column :ordrs, :payment_on_file_at, :datetime
    add_column :ordrs, :viewed_bill_at, :datetime
    add_column :ordrs, :auto_pay_enabled, :boolean, default: false, null: false
    add_column :ordrs, :auto_pay_consent_at, :datetime
    add_column :ordrs, :auto_pay_attempted_at, :datetime
    add_column :ordrs, :auto_pay_status, :string
    add_column :ordrs, :auto_pay_failure_reason, :text

    add_index :ordrs, :payment_on_file, where: 'payment_on_file = true'
    add_index :ordrs, :auto_pay_enabled, where: 'auto_pay_enabled = true'
    add_index :ordrs, :auto_pay_status
  end
end
