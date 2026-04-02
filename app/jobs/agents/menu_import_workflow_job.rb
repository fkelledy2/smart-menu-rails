# frozen_string_literal: true

module Agents
  # Agents::MenuImportWorkflowJob receives an AgentWorkflowRun ID and delegates
  # execution to Agents::Workflows::MenuImportWorkflow.
  # Queue: agent_high (high-priority agent queue)
  # Idempotent: skips if the run is already terminal.
  class MenuImportWorkflowJob < ApplicationJob
    queue_as :agent_high

    # @param workflow_run_id [Integer]
    def perform(workflow_run_id)
      run = AgentWorkflowRun.find_by(id: workflow_run_id)

      unless run
        Rails.logger.warn("[Agents::MenuImportWorkflowJob] Run #{workflow_run_id} not found — skipping")
        return
      end

      if run.cancelled? || run.completed?
        Rails.logger.info("[Agents::MenuImportWorkflowJob] Run #{workflow_run_id} already terminal — skipping")
        return
      end

      unless Flipper.enabled?(:agent_menu_import, run.restaurant)
        Rails.logger.info("[Agents::MenuImportWorkflowJob] agent_menu_import flag disabled for restaurant #{run.restaurant_id}")
        return
      end

      Agents::Workflows::MenuImportWorkflow.call(run)
    end
  end
end
