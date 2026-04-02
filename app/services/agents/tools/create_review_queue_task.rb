# frozen_string_literal: true

module Agents
  module Tools
    # Creates an AgentApproval record and routes it to the appropriate manager.
    class CreateReviewQueueTask < BaseTool
      def self.tool_name
        'create_review_queue_task'
      end

      def self.description
        'Create a human review task for the restaurant manager for a proposed action.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            workflow_run_id: { type: 'integer' },
            action_type: { type: 'string' },
            risk_level: { type: 'string', enum: %w[low medium high], default: 'medium' },
            proposed_payload: { type: 'object' },
          },
          required: %w[workflow_run_id action_type proposed_payload],
        }
      end

      def self.call(params)
        run = AgentWorkflowRun.find(params['workflow_run_id'] || params[:workflow_run_id])

        result = Agents::ApprovalRouter.call(
          workflow_run: run,
          action_type: params['action_type'],
          risk_level: params.fetch('risk_level', 'medium'),
          proposed_payload: params['proposed_payload'] || {},
        )

        raise result.error unless result.success?

        { approval_id: result.approval.id, status: 'pending' }
      end
    end
  end
end
