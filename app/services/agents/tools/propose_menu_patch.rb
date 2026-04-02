# frozen_string_literal: true

module Agents
  module Tools
    # Writes a structured menu diff to AgentArtifact as a draft.
    # Requires approval before any live data is mutated.
    class ProposeMenuPatch < BaseTool
      def self.tool_name
        'propose_menu_patch'
      end

      def self.description
        'Write a proposed menu patch (add/update/remove items or sections) as a draft artifact for review.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            workflow_run_id: { type: 'integer' },
            changes: {
              type: 'array',
              description: 'Array of change operations',
              items: {
                type: 'object',
                properties: {
                  op: { type: 'string', enum: %w[add update remove] },
                  target: { type: 'string', enum: %w[item section] },
                  id: { type: 'integer', description: 'Existing record ID (for update/remove)' },
                  data: { type: 'object', description: 'Fields to set (for add/update)' },
                },
                required: %w[op target],
              },
            },
            rationale: { type: 'string', description: 'Why this patch is being proposed' },
          },
          required: %w[workflow_run_id changes],
        }
      end

      def self.call(params)
        run_id = params['workflow_run_id'] || params[:workflow_run_id]
        run    = AgentWorkflowRun.find(run_id)

        result = Agents::ArtifactWriter.call(
          workflow_run: run,
          artifact_type: 'menu_patch',
          content: {
            changes: params['changes'] || [],
            rationale: params['rationale'],
            proposed_at: Time.current.iso8601,
          },
        )

        raise result.error unless result.success?

        { artifact_id: result.artifact.id, status: 'draft' }
      end
    end
  end
end
