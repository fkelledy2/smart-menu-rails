class LedgerEvent < ApplicationRecord
  enum :provider, {
    stripe: 0,
  }

  enum :entity_type, {
    payment_attempt: 0,
    refund: 10,
    transfer: 20,
    dispute: 30,
    payout: 40,
  }

  enum :event_type, {
    created: 0,
    authorized: 10,
    captured: 20,
    succeeded: 30,
    failed: 40,
    refunded: 50,
    dispute_opened: 60,
  }

  validates :provider, presence: true
  validates :provider_event_id, presence: true
  validates :entity_type, presence: true
  validates :event_type, presence: true
end
