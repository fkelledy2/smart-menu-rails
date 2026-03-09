class CreatePaymentRefunds < ActiveRecord::Migration[7.2]
  def change
    create_table :payment_refunds do |t|
      t.references :payment_attempt, null: false, foreign_key: true
      t.references :ordr, null: false, foreign_key: true
      t.references :restaurant, null: false, foreign_key: true

      t.integer :provider, null: false, default: 0
      t.string :provider_refund_id

      t.integer :amount_cents
      t.string :currency

      t.integer :status, null: false, default: 0
      t.jsonb :provider_response_payload, null: false, default: {}

      t.timestamps
    end

    add_index :payment_refunds, %i[provider provider_refund_id], unique: true, where: "provider_refund_id IS NOT NULL"
    add_index :payment_refunds, %i[payment_attempt_id created_at]
  end
end
