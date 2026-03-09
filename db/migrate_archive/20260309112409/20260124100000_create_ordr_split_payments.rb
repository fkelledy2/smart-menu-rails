class CreateOrdrSplitPayments < ActiveRecord::Migration[7.2]
  def change
    create_table :ordr_split_payments do |t|
      t.references :ordr, null: false, foreign_key: true
      t.references :ordrparticipant, null: true, foreign_key: true

      t.integer :amount_cents, null: false
      t.string :currency, null: false
      t.integer :status, null: false, default: 0

      t.string :stripe_checkout_session_id
      t.string :stripe_payment_intent_id

      t.timestamps
    end

    add_index :ordr_split_payments, :stripe_checkout_session_id, unique: true
    add_index :ordr_split_payments, :stripe_payment_intent_id
  end
end
