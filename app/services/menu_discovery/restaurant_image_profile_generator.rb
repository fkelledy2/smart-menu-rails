module MenuDiscovery
  class RestaurantImageProfileGenerator
    MAX_INPUT_LENGTH = 3000

    def initialize(client: nil)
      @client = client || Rails.configuration.x.openai_client
    end

    def generate(raw_text:, restaurant_name:, description: nil, establishment_types: [], website_url: nil)
      return {} if @client.nil?

      input = raw_text.to_s.strip[0, MAX_INPUT_LENGTH]
      types_str = Array(establishment_types).reject(&:blank?).join(', ')

      system_msg = <<~PROMPT.strip
        You are an expert at understanding restaurant brand identity and translating it into visual direction for AI image generation.

        Given context about a restaurant, produce two fields:

        1. **image_context** (max 120 chars): A short phrase describing the restaurant's visual setting and atmosphere.
           Examples: "rustic French bistro with candlelit tables and exposed brick walls"
           Examples: "modern minimalist sushi counter with blonde wood and soft lighting"

        2. **image_style_profile** (max 300 chars): Detailed visual direction for generating images of this restaurant's dishes and interior.
           Cover: lighting style, colour palette, plating style, table setting, background elements, mood.
           Example: "Warm tungsten lighting, earthy tones with deep burgundy accents. Rustic ceramic plates on weathered oak tables. Soft bokeh background of wine bottles and copper pans. Cozy, intimate mood."

        Return ONLY valid JSON with keys "image_context" and "image_style_profile". No markdown, no explanation.
      PROMPT

      user_msg = "Restaurant: #{restaurant_name}"
      user_msg += "\nType: #{types_str}" if types_str.present?
      user_msg += "\nDescription: #{description}" if description.present?
      user_msg += "\nWebsite: #{website_url}" if website_url.present?
      user_msg += "\n\nRaw website text:\n#{input}" if input.present?

      params = {
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: system_msg },
          { role: 'user', content: user_msg },
        ],
        temperature: 0.7,
        max_tokens: 300,
      }

      resp = @client.chat(parameters: params)
      content = resp.dig('choices', 0, 'message', 'content').to_s.strip
      return {} if content.blank?

      parsed = JSON.parse(content)
      {
        'image_context' => parsed['image_context'].to_s.strip.presence,
        'image_style_profile' => parsed['image_style_profile'].to_s.strip.presence,
      }.compact
    rescue JSON::ParserError => e
      Rails.logger.warn("[RestaurantImageProfileGenerator] JSON parse error: #{e.message}")
      {}
    rescue StandardError => e
      Rails.logger.warn("[RestaurantImageProfileGenerator] OpenAI error: #{e.message}")
      {}
    end
  end
end
