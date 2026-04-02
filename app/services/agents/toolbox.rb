# frozen_string_literal: true

module Agents
  # Agents::Toolbox is a registry of callable tool objects.
  # Each tool wraps an existing service object and logs every invocation
  # in ToolInvocationLog. Tools contain no business logic themselves.
  #
  # Usage (from within Runner):
  #   result = Agents::Toolbox.invoke(
  #     tool_name: 'read_restaurant_context',
  #     params: { restaurant_id: 42 },
  #     step: agent_workflow_step,
  #   )
  class Toolbox
    class ToolNotFoundError < StandardError; end
    class ToolExecutionError < StandardError; end

    class << self
      def registry
        @registry ||= {}
      end

      # Register a tool class.
      # @param tool_class [Class] must implement .name, .description, .input_schema, .call(params)
      def register(tool_class)
        registry[tool_class.tool_name.to_s] = tool_class
      end

      def tool_definitions
        registry.values.map do |klass|
          {
            type: 'function',
            function: {
              name: klass.tool_name,
              description: klass.description,
              parameters: klass.input_schema,
            },
          }
        end
      end

      # Invoke a registered tool, wrapping execution with ToolInvocationLog persistence.
      # @param tool_name [String]
      # @param params    [Hash]
      # @param step      [AgentWorkflowStep] the step invoking this tool
      # @return [Hash] the tool's output
      def invoke(tool_name:, params:, step:)
        tool_class = registry[tool_name.to_s]
        raise ToolNotFoundError, "Unknown tool: #{tool_name}" unless tool_class

        started_at = Time.current
        begin
          output = tool_class.call(params)
          duration_ms = ((Time.current - started_at) * 1000).to_i

          ToolInvocationLog.create!(
            agent_workflow_step: step,
            tool_name: tool_name,
            input_params: params,
            output_payload: output,
            status: 'success',
            duration_ms: duration_ms,
            invoked_at: started_at,
          )

          output
        rescue StandardError => e
          duration_ms = ((Time.current - started_at) * 1000).to_i

          ToolInvocationLog.create!(
            agent_workflow_step: step,
            tool_name: tool_name,
            input_params: params,
            output_payload: { error: e.message },
            status: 'error',
            duration_ms: duration_ms,
            invoked_at: started_at,
          )

          raise ToolExecutionError, "Tool #{tool_name} failed: #{e.message}"
        end
      end
    end
  end
end
