class PaymentAttempt < ApplicationRecord
  belongs_to :ordr
  belongs_to :restaurant

  has_many :payment_refunds, dependent: :destroy

  # provider_checkout_url is a Stripe/Square session URL — encrypt at rest.
  # provider_payment_id is excluded: it has a unique DB index which would break
  # with non-deterministic encryption and is needed for idempotency checks.
  encrypts :provider_checkout_url

  enum :provider, {
    stripe: 0,
    square: 1,
  }

  enum :status, {
    requires_action: 0,
    processing: 10,
    succeeded: 20,
    failed: 30,
    canceled: 40,
  }

  enum :charge_pattern, {
    direct: 0,
    destination: 10,
    separate: 20,
  }

  enum :merchant_model, {
    restaurant_mor: 0,
    smartmenu_mor: 1,
  }

  validates :provider, presence: true
  validates :amount_cents, numericality: { greater_than: 0, only_integer: true }
  validates :currency, presence: true
  validates :status, presence: true
  validates :charge_pattern, presence: true
  validates :merchant_model, presence: true
  validates :idempotency_key, uniqueness: true, allow_nil: true
end
