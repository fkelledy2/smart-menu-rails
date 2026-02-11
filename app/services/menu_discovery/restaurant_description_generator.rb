module MenuDiscovery
  class RestaurantDescriptionGenerator
    MAX_INPUT_LENGTH = 3000

    def initialize(client: nil)
      @client = client || Rails.configuration.x.openai_client
    end

    def generate(raw_about_text:, restaurant_name:, establishment_types: [], website_url: nil)
      return nil if @client.nil?
      return nil if raw_about_text.to_s.strip.blank?

      input = raw_about_text.to_s.strip[0, MAX_INPUT_LENGTH]
      types_str = Array(establishment_types).compact_blank.join(', ')

      system_msg = <<~PROMPT.strip
        You are a skilled copywriter for a restaurant discovery platform.
        Given raw text scraped from a restaurant's website, write a concise, engaging description (2-3 sentences, max 280 characters).
        Capture the restaurant's essence: cuisine style, ambiance, what makes it special.
        Do NOT include the restaurant name, address, phone number, or opening hours in the description.
        Do NOT use marketing clichés like "hidden gem" or "culinary journey".
        Write in third person. Be specific and authentic.
        Return ONLY the description text, nothing else.
      PROMPT

      user_msg = "Restaurant: #{restaurant_name}"
      user_msg += "\nType: #{types_str}" if types_str.present?
      user_msg += "\nWebsite: #{website_url}" if website_url.present?
      user_msg += "\n\nRaw website text:\n#{input}"

      params = {
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: system_msg },
          { role: 'user', content: user_msg },
        ],
        temperature: 0.7,
        max_tokens: 200,
      }

      resp = @client.chat(parameters: params)
      content = resp.dig('choices', 0, 'message', 'content').to_s.strip
      return nil if content.blank?

      content.gsub(/[\s\n]+/, ' ').strip
    rescue StandardError => e
      Rails.logger.warn("[RestaurantDescriptionGenerator] OpenAI error: #{e.message}")
      nil
    end
  end
end
