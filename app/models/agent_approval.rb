# frozen_string_literal: true

# AgentApproval represents a human-in-the-loop gate for a proposed agent action.
# Created by `Agents::ApprovalRouter` whenever PolicyEvaluator returns :require_approval.
# Expires after a configurable window (default 72 hours) via ExpireAgentApprovalsJob.
class AgentApproval < ApplicationRecord
  STATUSES    = %w[pending approved rejected expired].freeze
  RISK_LEVELS = %w[low medium high].freeze

  DEFAULT_EXPIRY_HOURS = 72

  belongs_to :agent_workflow_run
  belongs_to :agent_workflow_step, optional: true
  belongs_to :reviewer, class_name: 'User', optional: true

  validates :action_type, presence: true
  validates :status,     inclusion: { in: STATUSES }
  validates :risk_level, inclusion: { in: RISK_LEVELS }
  validates :expires_at, presence: true

  scope :pending, -> { where(status: 'pending') }
  scope :expired_but_not_marked, -> { pending.where(expires_at: ..Time.current) }

  def pending?  = status == 'pending'
  def approved? = status == 'approved'
  def rejected? = status == 'rejected'
  def expired?  = status == 'expired'

  def expired_at_time?
    expires_at.present? && expires_at <= Time.current
  end

  def approve!(reviewer, notes: nil)
    raise 'Cannot approve an expired approval' if expired_at_time?

    update!(
      status: 'approved',
      reviewer: reviewer,
      reviewed_at: Time.current,
      reviewer_notes: notes,
    )
  end

  def reject!(reviewer, notes: nil)
    update!(
      status: 'rejected',
      reviewer: reviewer,
      reviewed_at: Time.current,
      reviewer_notes: notes,
    )
  end

  def expire!
    update!(status: 'expired')
  end
end
