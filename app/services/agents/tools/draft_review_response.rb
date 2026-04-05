# frozen_string_literal: true

module Agents
  module Tools
    # Agents::Tools::DraftReviewResponse generates a professional public response
    # to a review (in-app or external). The manager edits and approves before posting.
    # Posting to external review platforms (Google/TripAdvisor) is out of scope for v1.
    class DraftReviewResponse < BaseTool
      LLM_MODEL       = 'gpt-4o'
      LLM_TEMPERATURE = 0

      def self.tool_name
        'draft_review_response'
      end

      def self.description
        'Generate a professional public response to a customer review for manager approval.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            review_text: {
              type: 'string',
              description: 'The full review text left by the customer.',
            },
            stars: {
              type: 'integer',
              description: 'Star rating (1–5).',
            },
            restaurant_name: {
              type: 'string',
              description: 'Name of the restaurant.',
            },
            restaurant_context: {
              type: 'object',
              description: 'Optional: restaurant details (cuisine type, location).',
            },
          },
          required: %w[review_text stars restaurant_name],
        }
      end

      def self.call(params)
        new(params).call
      end

      def initialize(params)
        @review_text         = params['review_text'].to_s
        @stars               = params['stars'].to_i
        @restaurant_name     = params['restaurant_name']
        @restaurant_context  = params['restaurant_context'] || {}
      end

      def call
        system_prompt = <<~PROMPT
          You are the manager of #{@restaurant_name} writing a public response to a customer review.
          Write a professional, empathetic, and concise response under 100 words.
          Do not be defensive. Acknowledge the feedback and invite the customer back if appropriate.
          Sign it "The #{@restaurant_name} Team". Return plain text only.
        PROMPT

        user_content = <<~CONTENT
          Review (#{@stars} stars): #{@review_text}
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

        draft = response.dig('choices', 0, 'message', 'content').to_s.strip
        { 'draft_review_response' => draft }
      rescue StandardError => e
        Rails.logger.warn("[DraftReviewResponse] OpenAI call failed: #{e.message}")
        { 'draft_review_response' => nil, 'error' => e.message }
      end
    end
  end
end
