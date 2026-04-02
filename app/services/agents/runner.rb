# frozen_string_literal: true

module Agents
  # Agents::Runner executes an AgentWorkflowRun step by step.
  # Key invariants:
  #   - No DB transaction spans an LLM API call.
  #   - Resumable: re-enqueueing resumes from the last completed step.
  #   - Each step is retried up to AgentWorkflowStep::MAX_RETRIES times.
  #   - PolicyEvaluator is called before any write-action tool invocation.
  class Runner
    LLM_MODEL   = 'gpt-4o'
    LLM_TIMEOUT = 120.seconds

    def self.call(workflow_run)
      new(workflow_run).call
    end

    def initialize(workflow_run)
      @run = workflow_run
    end

    def call
      return if @run.completed? || @run.cancelled?

      @run.mark_running! if @run.pending?

      steps = @run.agent_workflow_steps.ordered.to_a
      resume_from = @run.resume_from_step_index

      steps.each do |step|
        next if step.step_index < resume_from
        next if step.completed? || step.skipped?

        execute_step(step)

        # If the run entered awaiting_approval, pause execution.
        @run.reload
        break if @run.awaiting_approval?
      end

      # If we reach here without pausing, check if all steps are done.
      @run.reload
      complete_run_if_finished
    rescue StandardError => e
      Rails.logger.error("[Agents::Runner] Run #{@run.id} failed: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      @run.mark_failed!(e.message)
    end

    private

    def execute_step(step)
      step.mark_running!

      # Fetch context and call LLM (no transaction wrapping the API call)
      input = step.input_snapshot
      llm_response = call_llm(step, input)

      # Process tool calls returned by the LLM
      process_tool_calls(step, llm_response)

      step.mark_completed!(llm_response)
    rescue StandardError => e
      step.mark_failed!(e)

      # Retry if we haven't exhausted the limit
      raise unless step.retriable?

      Rails.logger.warn("[Agents::Runner] Retrying step #{step.id} (attempt #{step.retry_count})")
      retry

      # Propagate failure to abort the run
    end

    # Call the OpenAI Responses API with tool definitions.
    # Returns the parsed response hash.
    # NOTE: This method must NOT be wrapped in a DB transaction.
    def call_llm(step, input)
      client = openai_client

      system_prompt = build_system_prompt
      user_message  = input.to_json

      client.chat_with_tools(
        model: LLM_MODEL,
        messages: [
          { role: 'system', content: system_prompt },
          { role: 'user',   content: user_message },
        ],
        tools: Agents::Toolbox.tool_definitions,
      )
    end

    def process_tool_calls(step, llm_response)
      tool_calls = llm_response.dig('choices', 0, 'message', 'tool_calls') || []

      tool_calls.each do |tool_call|
        tool_name = tool_call.dig('function', 'name')
        params    = JSON.parse(tool_call.dig('function', 'arguments') || '{}')

        evaluation = Agents::PolicyEvaluator.call(
          action_type: tool_name,
          restaurant_id: @run.restaurant_id,
          proposed_payload: params,
        )

        case evaluation
        when :auto_approve
          Agents::Toolbox.invoke(tool_name: tool_name, params: params, step: step)
        when :require_approval
          Agents::ApprovalRouter.call(
            workflow_run: @run,
            action_type: tool_name,
            risk_level: risk_level_for(tool_name),
            proposed_payload: params,
            step: step,
          )
          # Stop processing further tool calls — run is now paused
          break
        when :blocked
          Rails.logger.warn("[Agents::Runner] Tool #{tool_name} is blocked for restaurant #{@run.restaurant_id}")
        end
      end
    end

    def complete_run_if_finished
      return if @run.awaiting_approval? || @run.failed? || @run.cancelled?

      all_done = @run.agent_workflow_steps.reload.all? { |s| s.completed? || s.skipped? }
      @run.mark_completed! if all_done
    end

    def risk_level_for(tool_name)
      policy = AgentPolicy.active
        .where(action_type: tool_name)
        .where('restaurant_id = ? OR restaurant_id IS NULL', @run.restaurant_id)
        .order(Arel.sql('restaurant_id IS NULL ASC'))
        .first

      # Look up from global defaults if no policy found
      if policy.nil?
        global = AgentPolicy::GLOBAL_DEFAULTS.find { |d| d[:action_type] == tool_name }
        global&.dig(:risk_level) || 'medium'
      else
        'medium' # AgentPolicy doesn't store risk_level independently in v1
      end
    end

    def build_system_prompt
      <<~PROMPT
        You are an AI assistant for the mellow.menu restaurant management platform.
        Your role is to help restaurant owners improve their operations using available tools.
        Always use tools to accomplish tasks — do not invent data.
        Be concise and precise. Never make changes without explicit tool calls.
      PROMPT
    end

    def openai_client
      OpenaiClient.new
    end
  end
end
