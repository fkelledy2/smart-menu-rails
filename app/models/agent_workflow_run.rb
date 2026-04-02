# frozen_string_literal: true

# AgentWorkflowRun tracks the lifecycle of a single AI agent workflow execution.
# Every agent invocation (menu import, growth digest, etc.) produces one run.
# Runs are restaurant-scoped and gated behind the `agent_framework` Flipper flag.
class AgentWorkflowRun < ApplicationRecord
  STATUSES = %w[pending running awaiting_approval completed failed cancelled].freeze

  belongs_to :restaurant
  has_many :agent_workflow_steps, dependent: :destroy
  has_many :agent_artifacts, dependent: :destroy
  has_many :agent_approvals, dependent: :destroy

  validates :workflow_type, presence: true
  validates :trigger_event, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :for_restaurant, ->(restaurant_id) { where(restaurant_id: restaurant_id) }
  scope :active, -> { where(status: %w[pending running awaiting_approval]) }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, -> { order(created_at: :desc) }

  def pending?   = status == 'pending'
  def running?   = status == 'running'
  def awaiting_approval? = status == 'awaiting_approval'
  def completed? = status == 'completed'
  def failed?    = status == 'failed'
  def cancelled? = status == 'cancelled'

  # Resume from the last completed step index (0-based).
  # Returns 0 if no steps are completed yet.
  def resume_from_step_index
    last_done = agent_workflow_steps.where(status: 'completed').maximum(:step_index)
    last_done.nil? ? 0 : last_done + 1
  end

  def mark_running!
    update!(status: 'running', started_at: Time.current)
  end

  def mark_completed!
    update!(status: 'completed', completed_at: Time.current)
  end

  def mark_failed!(error_message)
    update!(status: 'failed', error_message: error_message, completed_at: Time.current)
  end

  def mark_awaiting_approval!
    update!(status: 'awaiting_approval')
  end
end
