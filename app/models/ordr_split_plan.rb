class OrdrSplitPlan < ApplicationRecord
  belongs_to :ordr
  belongs_to :created_by_user, class_name: 'User', optional: true
  belongs_to :updated_by_user, class_name: 'User', optional: true

  has_many :ordr_split_payments, dependent: :destroy
  has_many :ordr_split_item_assignments, dependent: :destroy

  enum :split_method, {
    equal: 0,
    custom: 1,
    percentage: 2,
    item_based: 3,
  }, prefix: true

  enum :plan_status, {
    draft: 0,
    validated: 10,
    frozen: 20,
    completed: 30,
    failed: 40,
    canceled: 50,
  }, prefix: true

  validates :split_method, presence: true
  validates :plan_status, presence: true
  validate :ordr_in_payable_state, on: :create

  def split_frozen?
    frozen_at.present? || plan_status_frozen? || plan_status_completed?
  end

  def freeze!
    return if split_frozen?

    timestamp = Time.current
    transaction do
      update!(plan_status: :frozen, frozen_at: timestamp)
      ordr_split_payments.where(locked_at: nil).update_all(locked_at: timestamp)
    end
  end

  def any_share_in_flight?
    ordr_split_payments.any? { |share| share.pending? || share.succeeded? }
  end

  def all_shares_settled?
    ordr_split_payments.exists? && ordr_split_payments.all?(&:succeeded?)
  end

  def total_allocated_cents
    ordr_split_payments.sum(:amount_cents)
  end

  def update_status_from_settlement!
    return if plan_status_completed? || plan_status_canceled?

    if all_shares_settled?
      update!(plan_status: :completed)
    elsif any_share_failed?
      update!(plan_status: :failed)
    elsif any_share_in_flight?
      freeze! unless split_frozen?
    end
  end

  def any_share_failed?
    ordr_split_payments.any?(&:failed?)
  end

  private

  def ordr_in_payable_state
    return if ordr.nil? || ordr.billrequested?

    errors.add(:base, 'Split plan can only be created when order is billrequested')
  end
end
