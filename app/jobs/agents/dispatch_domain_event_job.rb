# frozen_string_literal: true

module Agents
  # Agents::DispatchDomainEventJob processes an AgentWorkflowRun by handing it off
  # to Agents::Runner. Lives on the agent_default queue.
  class DispatchDomainEventJob < ApplicationJob
    queue_as :agent_default

    # @param workflow_run_id [Integer]
    def perform(workflow_run_id)
      run = AgentWorkflowRun.find_by(id: workflow_run_id)

      unless run
        Rails.logger.warn("[Agents::DispatchDomainEventJob] Run #{workflow_run_id} not found — skipping")
        return
      end

      if run.cancelled? || run.completed?
        Rails.logger.info("[Agents::DispatchDomainEventJob] Run #{workflow_run_id} already terminal — skipping")
        return
      end

      Agents::Runner.call(run)
    end
  end
end
