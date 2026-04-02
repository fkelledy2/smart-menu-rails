# frozen_string_literal: true

# AgentArtifact holds the structured output of a workflow run.
# Artifacts start as `draft` and must be approved before being applied
# to live production data. `ArtifactWriter` is the only service that creates them.
class AgentArtifact < ApplicationRecord
  STATUSES = %w[draft approved rejected applied].freeze

  belongs_to :agent_workflow_run
  belongs_to :approved_by, class_name: 'User', optional: true

  validates :artifact_type, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :draft,    -> { where(status: 'draft') }
  scope :approved, -> { where(status: 'approved') }
  scope :applied,  -> { where(status: 'applied') }

  def draft?    = status == 'draft'
  def approved? = status == 'approved'
  def rejected? = status == 'rejected'
  def applied?  = status == 'applied'

  def approve!(user)
    update!(status: 'approved', approved_by: user, approved_at: Time.current)
  end

  def reject!(user)
    update!(status: 'rejected', approved_by: user, approved_at: Time.current)
  end

  def apply!
    raise 'Artifact must be approved before applying' unless approved?

    update!(status: 'applied')
  end
end
