# frozen_string_literal: true

module Agents
  # Agents::ArtifactWriter persists structured agent output as an AgentArtifact.
  # It never mutates live production models — writing to an artifact is the only
  # way an agent records a proposed change. Apply happens separately after approval.
  class ArtifactWriter
    Result = Struct.new(:success?, :artifact, :error, keyword_init: true)

    def self.call(workflow_run:, artifact_type:, content:)
      new(workflow_run: workflow_run, artifact_type: artifact_type, content: content).call
    end

    def initialize(workflow_run:, artifact_type:, content:)
      @workflow_run   = workflow_run
      @artifact_type  = artifact_type.to_s
      @content        = content
    end

    def call
      artifact = AgentArtifact.create!(
        agent_workflow_run: @workflow_run,
        artifact_type: @artifact_type,
        content: @content,
        status: 'draft',
      )

      Result.new(success?: true, artifact: artifact)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::NotNullViolation => e
      Result.new(success?: false, error: e.message)
    end
  end
end
