class OrdrSplitPayment < ApplicationRecord
  belongs_to :ordr
  belongs_to :ordrparticipant, optional: true

  enum :provider, {
    stripe: 0,
    square: 1,
  }

  enum :status, {
    pending: 0,
    requires_payment: 10,
    succeeded: 20,
    failed: 30,
    canceled: 40,
  }

  validates :amount_cents, presence: true
  validates :currency, presence: true
  validates :status, presence: true

  validates :provider_checkout_session_id, uniqueness: true, allow_nil: true
  validates :idempotency_key, uniqueness: true, allow_nil: true
end
