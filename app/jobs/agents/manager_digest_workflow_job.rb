# frozen_string_literal: true

module Agents
  # Agents::ManagerDigestWorkflowJob receives an AgentWorkflowRun ID and delegates
  # execution to Agents::Workflows::ManagerDigestWorkflow.
  # Queue: agent_default (weekly background work)
  # Idempotent: skips if the run is already terminal.
  class ManagerDigestWorkflowJob < ApplicationJob
    queue_as :agent_default

    # Retry with exponential backoff on OpenAI or transient DB errors.
    # After 3 retries a manager will receive a fallback digest (raw data only).
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    # @param workflow_run_id [Integer]
    def perform(workflow_run_id)
      run = AgentWorkflowRun.find_by(id: workflow_run_id)

      unless run
        Rails.logger.warn("[Agents::ManagerDigestWorkflowJob] Run #{workflow_run_id} not found — skipping")
        return
      end

      if run.cancelled? || run.completed?
        Rails.logger.info("[Agents::ManagerDigestWorkflowJob] Run #{workflow_run_id} already terminal — skipping")
        return
      end

      unless Flipper.enabled?(:agent_growth_digest, run.restaurant)
        Rails.logger.info(
          "[Agents::ManagerDigestWorkflowJob] agent_growth_digest flag disabled for restaurant #{run.restaurant_id}",
        )
        return
      end

      Agents::Workflows::ManagerDigestWorkflow.call(run)
    end
  end
end
