# frozen_string_literal: true

module Agents
  # Agents::MenuOptimizationWorkflowJob receives an AgentWorkflowRun ID and
  # delegates execution to Agents::Workflows::MenuOptimizationWorkflow.
  # Queue: agent_default
  # Idempotent: skips if the run is already terminal.
  class MenuOptimizationWorkflowJob < ApplicationJob
    queue_as :agent_default

    # @param workflow_run_id [Integer]
    def perform(workflow_run_id)
      run = AgentWorkflowRun.find_by(id: workflow_run_id)

      unless run
        Rails.logger.warn("[Agents::MenuOptimizationWorkflowJob] Run #{workflow_run_id} not found — skipping")
        return
      end

      if run.cancelled? || run.completed?
        Rails.logger.info("[Agents::MenuOptimizationWorkflowJob] Run #{workflow_run_id} already terminal — skipping")
        return
      end

      unless Flipper.enabled?(:agent_menu_optimization, run.restaurant)
        Rails.logger.info(
          "[Agents::MenuOptimizationWorkflowJob] agent_menu_optimization flag disabled " \
          "for restaurant #{run.restaurant_id}",
        )
        return
      end

      Agents::Workflows::MenuOptimizationWorkflow.call(run)
    end
  end
end
