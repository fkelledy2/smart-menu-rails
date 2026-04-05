# frozen_string_literal: true

module Agents
  module Tools
    # Agents::Tools::DraftRecoveryMessage generates a personalised customer
    # recovery message via OpenAI. Strictly grounded to the provided order context.
    class DraftRecoveryMessage < BaseTool
      LLM_MODEL       = 'gpt-4o'
      LLM_TEMPERATURE = 0

      def self.tool_name
        'draft_recovery_message'
      end

      def self.description
        'Generate a personalised recovery message for a customer based on their order and the issue identified.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            ordr_context: {
              type: 'object',
              description: 'Order context hash from read_order_context.',
            },
            root_cause: {
              type: 'string',
              enum: Agents::Workflows::ReputationFeedbackWorkflow::ROOT_CAUSES,
              description: 'Root cause category identified for this signal.',
            },
            signal_type: {
              type: 'string',
              enum: Agents::Workflows::ReputationFeedbackWorkflow::SIGNAL_TYPES,
              description: 'The type of negative signal.',
            },
            restaurant_name: {
              type: 'string',
              description: 'Name of the restaurant.',
            },
          },
          required: %w[ordr_context root_cause signal_type restaurant_name],
        }
      end

      def self.call(params)
        new(params).call
      end

      def initialize(params)
        @ordr_context    = params['ordr_context'] || {}
        @root_cause      = params['root_cause']
        @signal_type     = params['signal_type']
        @restaurant_name = params['restaurant_name']
      end

      def call
        system_prompt = <<~PROMPT
          You are a restaurant customer service manager at #{@restaurant_name}.
          Write a brief, warm, and professional recovery message addressed to the customer.

          CRITICAL: Only reference the specific items listed in the order context below.
          Do not invent or mention any menu items, prices, or details not present in the context.

          Keep the message under 120 words. Sign it "The #{@restaurant_name} Team".
          Return the message as plain text only — no JSON, no markdown.
        PROMPT

        user_content = <<~CONTENT
          Issue type: #{@root_cause.to_s.humanize.downcase}
          Signal: #{@signal_type}
          Table: #{@ordr_context['table_name']}
          Items: #{Array(@ordr_context['items']).map { |i| "#{i['quantity']}x #{i['name']}" }.join(', ')}
          Customer name: #{@ordr_context['customer_name'].presence || 'Customer'}
        CONTENT

        client   = OpenaiClient.new
        response = client.chat_with_tools(
          model: LLM_MODEL,
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user', content: user_content },
          ],
          tools: [],
          temperature: LLM_TEMPERATURE,
        )

        message = response.dig('choices', 0, 'message', 'content').to_s.strip
        { 'draft_message' => message }
      rescue StandardError => e
        Rails.logger.warn("[DraftRecoveryMessage] OpenAI call failed: #{e.message}")
        { 'draft_message' => nil, 'error' => e.message }
      end
    end
  end
end
