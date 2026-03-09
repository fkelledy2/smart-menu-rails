# frozen_string_literal: true

class MakeOrdrSplitPaymentsProviderAgnostic < ActiveRecord::Migration[7.2]
  def change
    # Rename Stripe-specific columns to provider-agnostic names
    rename_column :ordr_split_payments, :stripe_checkout_session_id, :provider_checkout_session_id
    rename_column :ordr_split_payments, :stripe_payment_intent_id, :provider_payment_id

    # Add provider discriminator (stripe: 0, square: 1)
    add_column :ordr_split_payments, :provider, :integer, default: 0, null: false

    # Add idempotency, tip tracking, and payer reference
    add_column :ordr_split_payments, :idempotency_key, :string
    add_column :ordr_split_payments, :tip_cents, :integer, default: 0, null: false
    add_column :ordr_split_payments, :payer_ref, :string

    # Indexes (rename_column auto-renames existing indexes in Postgres)
    add_index :ordr_split_payments, :idempotency_key, unique: true,
              where: "idempotency_key IS NOT NULL",
              name: "index_ordr_split_payments_on_idempotency_key"
    add_index :ordr_split_payments, [:provider, :provider_payment_id], unique: true,
              where: "provider_payment_id IS NOT NULL",
              name: "index_ordr_split_payments_on_provider_and_payment_id"
  end
end
