class OrdrSplitPayment < ApplicationRecord
  belongs_to :ordr
  belongs_to :ordr_split_plan, optional: true
  belongs_to :ordrparticipant, optional: true
  has_many :ordr_split_item_assignments, dependent: :destroy

  enum :provider, {
    stripe: 0,
    square: 1,
  }

  enum :split_method, {
    equal: 0,
    custom: 1,
    percentage: 2,
    item_based: 3,
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

  def locked?
    locked_at.present? || ordr_split_plan&.split_frozen?
  end

  def pay_ready?
    requires_payment? || failed?
  end
end
