class PaymentAttempt < ApplicationRecord
  belongs_to :ordr
  belongs_to :restaurant

  has_many :payment_refunds, dependent: :delete_all

  enum :provider, {
    stripe: 0,
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
end
