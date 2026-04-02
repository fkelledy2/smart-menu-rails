# frozen_string_literal: true

module Agents
  module Tools
    # Generates a natural-language shortlist narrative from a ranked item array.
    # Calls OpenAI and returns a structured array of { id, name, price, explanation }.
    # This tool is only used by CustomerConciergeService (synchronous path), not the
    # background Agents::Runner pipeline.
    class ComposeRecommendation < BaseTool
      LLM_MODEL       = 'gpt-4o'
      MAX_ITEMS       = 6
      MAX_CONV_TURNS  = 5

      def self.tool_name
        'compose_recommendation'
      end

      def self.description
        'Generate a personalised shortlist of menu items with per-item explanations using OpenAI.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            items: {
              type: 'array',
              description: 'Menu items to choose from (id, name, price)',
              items: { type: 'object' },
            },
            query: { type: 'string', description: 'Customer\'s natural language query' },
            locale: { type: 'string', default: 'en', description: 'BCP-47 locale code for response language' },
            conversation_history: {
              type: 'array',
              description: 'Previous conversation turns (max 5)',
              items: { type: 'object' },
            },
            restaurant_name: { type: 'string' },
            currency: { type: 'string', default: 'EUR' },
          },
          required: %w[items query],
        }
      end

      def self.call(params)
        items      = Array(params['items'] || params[:items]).first(30)
        query      = (params['query'] || params[:query]).to_s.strip
        locale     = (params['locale'] || params[:locale] || 'en').to_s
        currency   = (params['currency'] || params[:currency] || 'EUR').to_s
        restaurant = (params['restaurant_name'] || params[:restaurant_name]).to_s
        history    = Array(params['conversation_history'] || params[:conversation_history])
          .last(MAX_CONV_TURNS)

        system_prompt = build_system_prompt(locale, restaurant, currency)
        messages      = build_messages(system_prompt, history, query, items)

        client = OpenaiClient.new
        response = client.chat_with_tools(
          model: LLM_MODEL,
          messages: messages,
          tools: [],
          temperature: 0.5,
        )

        content = response.dig('choices', 0, 'message', 'content').to_s
        parse_recommendations(content, items)
      rescue StandardError => e
        Rails.logger.error("[Agents::Tools::ComposeRecommendation] #{e.class}: #{e.message}")
        { error: e.message, items: [] }
      end

      def self.build_system_prompt(locale, restaurant, currency)
        lang_instruction = locale == 'en' ? '' : " Respond entirely in the locale '#{locale}'."
        <<~PROMPT.strip
          You are a helpful menu concierge for #{restaurant.presence || 'this restaurant'}.
          Your job is to recommend up to #{MAX_ITEMS} menu items that best match the customer's request.
          Respond with a JSON array. Each element must have exactly these fields:
            - "id"          (integer, the item id from the provided menu)
            - "name"        (string)
            - "price"       (number, in #{currency})
            - "explanation" (string, one sentence, max 20 words, in plain language)
          Return ONLY the JSON array — no markdown fences, no extra text.#{lang_instruction}
          Never include items not in the provided list.
          Never invent items, prices, or allergen information.
        PROMPT
      end
      private_class_method :build_system_prompt

      def self.build_messages(system_prompt, history, query, items)
        item_list = items.map { |i| { id: i[:id] || i['id'], name: i[:name] || i['name'], price: i[:price] || i['price'] } }

        messages = [{ role: 'system', content: system_prompt }]

        # Inject prior conversation turns (already formatted as {role:, content:} hashes)
        history.each do |turn|
          role    = turn['role']    || turn[:role]
          content = turn['content'] || turn[:content]
          messages << { role: role, content: content } if role.present? && content.present?
        end

        user_content = <<~MSG.strip
          Menu items available:
          #{item_list.to_json}

          Customer request: #{query}
        MSG

        messages << { role: 'user', content: user_content }
        messages
      end
      private_class_method :build_messages

      # Attempt to parse JSON array out of the LLM response.
      # Falls back gracefully if parsing fails.
      def self.parse_recommendations(content, items)
        # Strip optional markdown fences
        json_str = content.gsub(/```json\s*/i, '').gsub(/```/, '').strip
        parsed   = JSON.parse(json_str)
        return { items: [] } unless parsed.is_a?(Array)

        # Validate each returned id actually exists in our item list
        valid_ids = items.map { |i| (i[:id] || i['id']).to_i }.to_set
        filtered  = parsed.select { |r| valid_ids.include?((r['id'] || r[:id]).to_i) }

        { items: filtered.first(MAX_ITEMS) }
      rescue JSON::ParserError, TypeError => e
        Rails.logger.warn("[Agents::Tools::ComposeRecommendation] parse error: #{e.message}")
        { items: [], parse_error: true }
      end
      private_class_method :parse_recommendations
    end
  end
end
