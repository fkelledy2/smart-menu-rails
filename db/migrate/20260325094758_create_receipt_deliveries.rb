class CreateReceiptDeliveries < ActiveRecord::Migration[7.2]
  def change
    create_table :receipt_deliveries do |t|
      t.bigint :ordr_id, null: false
      t.bigint :restaurant_id, null: false
      t.bigint :created_by_user_id
      t.string :recipient_email
      t.string :recipient_phone
      t.string :delivery_method, null: false, default: 'email'
      t.string :status, null: false, default: 'pending'
      t.datetime :sent_at
      t.text :error_message
      t.integer :retry_count, null: false, default: 0
      t.string :secure_token, null: false

      t.timestamps
    end

    add_index :receipt_deliveries, :ordr_id
    add_index :receipt_deliveries, :restaurant_id
    add_index :receipt_deliveries, :secure_token, unique: true
    add_index :receipt_deliveries, %i[ordr_id status]
    add_index :receipt_deliveries, :created_at

    add_foreign_key :receipt_deliveries, :ordrs
    add_foreign_key :receipt_deliveries, :restaurants
  end
end
