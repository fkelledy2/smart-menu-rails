# frozen_string_literal: true

module Agents
  module Tools
    # Calls OpenAI to generate a plain-language narrative summary string.
    # Used by growth digest and other reporting agents.
    class ComposeManagerSummary < BaseTool
      def self.tool_name
        'compose_manager_summary'
      end

      def self.description
        'Generate a plain-language narrative summary for a restaurant manager based on provided data.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            context: { type: 'object', description: 'Data to summarise' },
            tone: { type: 'string', enum: %w[formal casual], default: 'casual' },
          },
          required: ['context'],
        }
      end

      def self.call(params)
        client   = OpenaiClient.new
        context  = params['context'] || params[:context] || {}
        tone     = params.fetch('tone', 'casual')

        system_prompt = <<~PROMPT
          You are a concise restaurant business advisor. Generate a #{tone} one-paragraph
          summary suitable for a restaurant manager. Focus on actionable insights.
          Respond with plain text only — no markdown, no bullet points.
        PROMPT

        response = client.chat_with_tools(
          model: 'gpt-4o',
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user',   content: context.to_json },
          ],
          temperature: 0.3,
        )

        summary = response.dig('choices', 0, 'message', 'content') || ''

        { summary: summary }
      end
    end
  end
end
