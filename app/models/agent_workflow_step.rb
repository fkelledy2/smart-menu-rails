# frozen_string_literal: true

# AgentWorkflowStep represents one discrete step within an AgentWorkflowRun.
# Steps are created up-front for the entire pipeline so progress is visible
# from the start. Execution is sequential by step_index.
class AgentWorkflowStep < ApplicationRecord
  STATUSES = %w[pending running completed failed skipped].freeze
  MAX_RETRIES = 3

  belongs_to :agent_workflow_run
  has_many :tool_invocation_logs, dependent: :destroy
  has_many :agent_approvals, dependent: :destroy

  validates :step_name, presence: true
  validates :step_index, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :retry_count, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(step_index: :asc) }
  scope :pending_or_running, -> { where(status: %w[pending running]) }

  def pending?   = status == 'pending'
  def running?   = status == 'running'
  def completed? = status == 'completed'
  def failed?    = status == 'failed'
  def skipped?   = status == 'skipped'

  def retriable?
    failed? && retry_count < MAX_RETRIES
  end

  def mark_running!
    update!(status: 'running', started_at: Time.current)
  end

  def mark_completed!(output = {})
    update!(status: 'completed', output_snapshot: output, completed_at: Time.current)
  end

  def mark_failed!(error)
    update!(
      status: 'failed',
      last_error: error.to_s,
      retry_count: retry_count + 1,
      completed_at: Time.current,
    )
  end

  def mark_skipped!
    update!(status: 'skipped', completed_at: Time.current)
  end
end
