# frozen_string_literal: true

module Agents
  module Tools
    # Agents::Tools::DraftStaffMessage — generates an internal team briefing draft
    # via OpenAI. The draft is ALWAYS shown for manager review before sending.
    #
    # Params:
    #   restaurant_name [String] — used to personalise the message tone
    #   topic           [String] — the subject or context for the message
    #   tone            [String] — optional: 'formal', 'casual' (default: 'friendly')
    class DraftStaffMessage < BaseTool
      LLM_MODEL     = 'gpt-4o'
      MAX_TOKENS    = 300
      DEFAULT_TONE  = 'friendly'

      def self.tool_name
        'draft_staff_message'
      end

      def self.description
        'Generate an internal team briefing message draft for manager review. Always requires human review before sending.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            restaurant_name: { type: 'string', description: 'The restaurant name' },
            topic: { type: 'string', description: 'Message topic or context' },
            tone: { type: 'string', enum: %w[formal friendly casual], description: 'Tone of the message' },
          },
          required: %w[restaurant_name topic],
        }
      end

      def self.call(params)
        new(params).call
      end

      def initialize(params)
        @restaurant_name = params['restaurant_name'] || params[:restaurant_name]
        @topic           = params['topic'] || params[:topic]
        @tone            = params['tone'] || params[:tone] || DEFAULT_TONE
      end

      def call
        response = openai_client.chat_with_tools(
          model: LLM_MODEL,
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user', content: user_message },
          ],
          tools: [],
          temperature: 0.7,
        )

        content = response.dig('choices', 0, 'message', 'content').to_s.strip
        parse_draft(content)
      rescue StandardError => e
        Rails.logger.warn("[DraftStaffMessage] LLM call failed: #{e.message}")
        {
          subject: 'Team Update',
          body: "Please draft your message here.\n\nTopic: #{@topic}",
        }
      end

      private

      def system_prompt
        <<~PROMPT
          You are a helpful assistant for #{@restaurant_name}, a restaurant management platform.
          Write a brief, #{@tone} internal staff message about the given topic.
          Keep it under 150 words. Professional yet warm.
          Reply ONLY with a JSON object: {"subject":"<short subject line>","body":"<message body>"}
          No markdown fences. No extra text.
        PROMPT
      end

      def user_message
        "Write a staff message about: #{@topic}"
      end

      def parse_draft(content)
        json = JSON.parse(content)
        {
          subject: json['subject'].to_s.strip.presence || 'Team Update',
          body: json['body'].to_s.strip.presence || content,
        }
      rescue JSON::ParserError
        {
          subject: 'Team Update',
          body: content.presence || "Please draft your message here.\n\nTopic: #{@topic}",
        }
      end

      def openai_client
        @openai_client ||= OpenaiClient.new
      end
    end
  end
end
