# frozen_string_literal: true

module Agents
  module Tools
    # Calls OpenAI to generate social/email marketing copy for a menu item.
    # Used by the Restaurant Growth Agent (workflow step: copy_draft).
    # Temperature 0.7 for creative variation.
    class DraftMarketingCopy < BaseTool
      LLM_MODEL = 'gpt-4o'
      LLM_TEMPERATURE = 0.7

      def self.tool_name
        'draft_marketing_copy'
      end

      def self.description
        'Generate Instagram caption and short email marketing copy for a featured menu item.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            item_name: { type: 'string', description: 'Name of the featured menu item' },
            item_description: { type: 'string', description: 'Description of the item (may be blank)' },
            restaurant_name: { type: 'string', description: 'Name of the restaurant' },
            establishment_type: { type: 'string', description: 'e.g. casual dining, fine dining, pub, café' },
            tone: {
              type: 'string',
              enum: %w[fun professional warm playful],
              description: 'Desired tone for the copy',
            },
          },
          required: %w[item_name restaurant_name],
        }
      end

      def self.call(params)
        client             = OpenaiClient.new
        item_name          = params['item_name'] || params[:item_name] || ''
        item_description   = params['item_description'] || params[:item_description] || ''
        restaurant_name    = params['restaurant_name'] || params[:restaurant_name] || ''
        establishment_type = params['establishment_type'] || params[:establishment_type] || 'restaurant'
        tone               = params['tone'] || params[:tone] || 'warm'

        system_prompt = <<~PROMPT
          You are a creative food and restaurant marketing copywriter.
          Write two pieces of marketing copy for the item described below.

          Tone: #{tone}
          Restaurant: #{restaurant_name} (#{establishment_type})

          Return ONLY a valid JSON object with exactly these two keys:
          {
            "instagram_caption": "string — 1–3 short sentences with 2–4 relevant hashtags",
            "email_body": "string — 2–4 sentences suitable for a promotional email or newsletter"
          }
          No markdown fences. No extra keys.
        PROMPT

        user_message = "Item: #{item_name}"
        user_message += "\nDescription: #{item_description}" if item_description.present?

        response = client.chat_with_tools(
          model: LLM_MODEL,
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user', content: user_message },
          ],
          tools: [],
          temperature: LLM_TEMPERATURE,
        )

        content = response.dig('choices', 0, 'message', 'content').to_s
        parsed  = parse_json(content)

        {
          instagram_caption: parsed.fetch('instagram_caption', ''),
          email_body: parsed.fetch('email_body', ''),
        }
      rescue StandardError => e
        Rails.logger.warn("[Agents::Tools::DraftMarketingCopy] Error: #{e.message}")
        { instagram_caption: '', email_body: '' }
      end

      # ---------------------------------------------------------------------------
      # Private
      # ---------------------------------------------------------------------------

      def self.parse_json(content)
        stripped = content.gsub(/```(?:json)?\n?/, '').gsub('```', '').strip
        JSON.parse(stripped)
      rescue JSON::ParserError
        match = content.match(/\{.*\}/m)
        raise JSON::ParserError, 'No JSON object found in LLM response' unless match

        JSON.parse(match[0])
      end
      private_class_method :parse_json
    end
  end
end
