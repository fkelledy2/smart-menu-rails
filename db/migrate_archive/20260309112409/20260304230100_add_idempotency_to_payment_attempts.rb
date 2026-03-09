# frozen_string_literal: true

class AddIdempotencyToPaymentAttempts < ActiveRecord::Migration[7.2]
  def change
    add_column :payment_attempts, :idempotency_key, :string
    add_column :payment_attempts, :tip_cents, :integer, default: 0, null: false
    add_column :payment_attempts, :provider_checkout_url, :string

    add_index :payment_attempts, :idempotency_key, unique: true,
              where: "idempotency_key IS NOT NULL",
              name: "index_payment_attempts_on_idempotency_key"
  end
end
