class PaymentRefund < ApplicationRecord
  belongs_to :payment_attempt
  belongs_to :ordr
  belongs_to :restaurant

  enum :provider, {
    stripe: 0,
  }

  enum :status, {
    pending: 0,
    processing: 10,
    succeeded: 20,
    failed: 30,
    canceled: 40,
  }

  validates :payment_attempt, presence: true
  validates :ordr, presence: true
  validates :restaurant, presence: true
  validates :provider, presence: true
  validates :status, presence: true
end
