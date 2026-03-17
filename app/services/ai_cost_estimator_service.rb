class AiCostEstimatorService
  def initialize(openai_client: nil)
    @client = openai_client || OpenAI::Client.new(access_token: Rails.application.credentials.dig(:openai, :api_key))
  end

  def estimate_costs_for_menu_item(name:, description:, price:, category: nil)
    prompt = build_prompt(name, description, price, category)

    response = @client.chat(parameters: {
      model: 'gpt-4',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.3,
    })

    parse_response(response.dig('choices', 0, 'message', 'content'))
  rescue StandardError => e
    Rails.logger.error("AI cost estimation failed: #{e.message}")
    nil
  end

  private

  def build_prompt(name, description, price, category)
    <<~PROMPT
      Estimate production costs for this menu item. Return JSON only.

      Item: #{name}
      Description: #{description || 'N/A'}
      Price: $#{price}
      Category: #{category || 'Unknown'}

      Estimate these costs as percentages of price:
      - ingredient_cost (typically 28-35% of price)
      - labor_cost (typically 25-35% of price)
      - packaging_cost (typically 3-8% of price)
      - overhead_cost (typically 10-15% of price)

      Return JSON: {"ingredient_cost": 0.00, "labor_cost": 0.00, "packaging_cost": 0.00, "overhead_cost": 0.00, "confidence": 0.75, "notes": "reasoning"}
    PROMPT
  end

  def parse_response(content)
    json_match = content.match(/\{.*\}/m)
    return nil unless json_match

    data = JSON.parse(json_match[0])
    {
      ingredient_cost: data['ingredient_cost'].to_f,
      labor_cost: data['labor_cost'].to_f,
      packaging_cost: data['packaging_cost'].to_f,
      overhead_cost: data['overhead_cost'].to_f,
      confidence: data['confidence'].to_f,
      notes: data['notes'],
    }
  rescue JSON::ParserError
    nil
  end
end
