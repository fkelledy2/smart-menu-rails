# frozen_string_literal: true

# ToolInvocationLog records every tool call made during an agent workflow step.
# No silent mutations — every call to a tool wrapper is captured here.
# Recommended retention: 90 days (confirm with legal/compliance before enforcing).
class ToolInvocationLog < ApplicationRecord
  STATUSES = %w[success error timeout].freeze

  belongs_to :agent_workflow_step

  validates :tool_name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :invoked_at, presence: true

  scope :successful, -> { where(status: 'success') }
  scope :errors,     -> { where(status: 'error') }
  scope :for_tool,   ->(name) { where(tool_name: name) }
  scope :recent,     -> { order(invoked_at: :desc) }

  # Purge logs older than the given time — call this from a maintenance job.
  def self.purge_before(time)
    where(invoked_at: ...time).delete_all
  end

  def success?  = status == 'success'
  def error?    = status == 'error'
  def timeout?  = status == 'timeout'
end
