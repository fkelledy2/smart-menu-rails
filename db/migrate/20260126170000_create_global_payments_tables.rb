class CreateGlobalPaymentsTables < ActiveRecord::Migration[7.2]
  def change
    create_table :payment_profiles do |t|
      t.references :restaurant, null: false, foreign_key: true, index: { unique: true }

      t.integer :merchant_model, null: false, default: 0
      t.integer :primary_provider, null: false, default: 0

      t.jsonb :fallback_providers, null: false, default: {}
      t.string :default_country
      t.string :default_currency
      t.jsonb :fee_model, null: false, default: {}

      t.timestamps
    end

    create_table :provider_accounts do |t|
      t.references :restaurant, null: false, foreign_key: true

      t.integer :provider, null: false, default: 0
      t.string :provider_account_id, null: false
      t.string :account_type
      t.string :country
      t.string :currency
      t.integer :status, null: false, default: 0
      t.jsonb :capabilities, null: false, default: {}
      t.boolean :payouts_enabled, null: false, default: false

      t.timestamps
    end

    add_index :provider_accounts, %i[provider provider_account_id], unique: true
    add_index :provider_accounts, %i[restaurant_id provider]

    create_table :payment_attempts do |t|
      t.references :ordr, null: false, foreign_key: true
      t.references :restaurant, null: false, foreign_key: true

      t.integer :provider, null: false, default: 0
      t.string :provider_payment_id

      t.integer :amount_cents, null: false
      t.string :currency, null: false

      t.integer :status, null: false, default: 0
      t.integer :charge_pattern, null: false, default: 0
      t.integer :merchant_model, null: false, default: 0

      t.integer :platform_fee_cents
      t.integer :provider_fee_cents

      t.timestamps
    end

    add_index :payment_attempts, %i[ordr_id created_at]
    add_index :payment_attempts, %i[restaurant_id created_at]
    add_index :payment_attempts, %i[provider provider_payment_id], unique: true, where: "provider_payment_id IS NOT NULL"

    create_table :ledger_events do |t|
      t.integer :entity_type, null: false, default: 0
      t.bigint :entity_id

      t.integer :event_type, null: false, default: 0

      t.integer :amount_cents
      t.string :currency

      t.integer :provider, null: false, default: 0
      t.string :provider_event_id, null: false
      t.string :provider_event_type

      t.jsonb :raw_event_payload, null: false, default: {}
      t.datetime :occurred_at

      t.timestamps
    end

    add_index :ledger_events, %i[provider provider_event_id], unique: true
    add_index :ledger_events, %i[entity_type entity_id]
    add_index :ledger_events, :occurred_at
  end
end
