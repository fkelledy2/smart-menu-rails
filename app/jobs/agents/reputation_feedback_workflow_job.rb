# frozen_string_literal: true

module Agents
  # Agents::ReputationFeedbackWorkflowJob receives an AgentWorkflowRun ID and
  # delegates execution to Agents::Workflows::ReputationFeedbackWorkflow.
  # Queue: agent_high — reputation signals are time-sensitive (target: < 5 min).
  # Idempotent: skips if the run is already terminal.
  class ReputationFeedbackWorkflowJob < ApplicationJob
    queue_as :agent_high

    # @param workflow_run_id [Integer]
    def perform(workflow_run_id)
      run = AgentWorkflowRun.find_by(id: workflow_run_id)

      unless run
        Rails.logger.warn("[Agents::ReputationFeedbackWorkflowJob] Run #{workflow_run_id} not found — skipping")
        return
      end

      if run.cancelled? || run.completed?
        Rails.logger.info("[Agents::ReputationFeedbackWorkflowJob] Run #{workflow_run_id} already terminal — skipping")
        return
      end

      unless Flipper.enabled?(:agent_reputation_feedback, run.restaurant)
        Rails.logger.info(
          "[Agents::ReputationFeedbackWorkflowJob] agent_reputation_feedback flag disabled " \
          "for restaurant #{run.restaurant_id}",
        )
        return
      end

      Agents::Workflows::ReputationFeedbackWorkflow.call(run)
    end
  end
end
