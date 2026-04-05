# frozen_string_literal: true

module Agents
  # Agents::ServiceOperationsWorkflowJob receives an AgentWorkflowRun ID and
  # delegates execution to Agents::Workflows::ServiceOperationsWorkflow.
  # Queue: agent_realtime (high concurrency for burst events during peak service)
  # Idempotent: skips if the run is already terminal.
  class ServiceOperationsWorkflowJob < ApplicationJob
    queue_as :agent_realtime

    # @param workflow_run_id [Integer]
    def perform(workflow_run_id)
      run = AgentWorkflowRun.find_by(id: workflow_run_id)

      unless run
        Rails.logger.warn("[Agents::ServiceOperationsWorkflowJob] Run #{workflow_run_id} not found — skipping")
        return
      end

      if run.cancelled? || run.completed?
        Rails.logger.info("[Agents::ServiceOperationsWorkflowJob] Run #{workflow_run_id} already terminal — skipping")
        return
      end

      unless Flipper.enabled?(:agent_service_operations, run.restaurant)
        Rails.logger.info(
          "[Agents::ServiceOperationsWorkflowJob] agent_service_operations flag disabled " \
          "for restaurant #{run.restaurant_id}",
        )
        return
      end

      Agents::Workflows::ServiceOperationsWorkflow.call(run)
    end
  end
end
