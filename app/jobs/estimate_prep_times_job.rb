require 'sidekiq'

class EstimatePrepTimesJob
  include Sidekiq::Job

  sidekiq_options queue: 'default', retry: 3

  def perform(menu_id = nil)
    menu = menu_id ? Menu.find_by(id: menu_id) : nil
    return if menu_id && menu.nil?

    items = menu ? menu.menuitems : Menuitem.where.not(archived: true)
    processed = 0

    items.find_each do |item|
      next if item.preptime.to_i.positive?

      estimated = estimate_via_llm(item) || estimate_heuristic(item.name, item.description, item.itemtype)
      if estimated.positive?
        item.update_column(:preptime, estimated)
        processed += 1
      end
    rescue StandardError => e
      Rails.logger.warn("[EstimatePrepTimesJob] Failed for item ##{item.id}: #{e.message}")
    end

    Rails.logger.info("[EstimatePrepTimesJob] Updated #{processed} items")
  end

  private

  def estimate_via_llm(item)
    return nil unless openai_client

    prompt = <<~PROMPT
      Estimate the kitchen preparation time in minutes for this menu item.
      Name: #{item.name}
      Description: #{item.description}

      Consider cooking method, ingredients, and complexity.
      Respond with ONLY a number (minutes). Examples: 5, 10, 15, 20, 25
    PROMPT

    response = openai_client.chat(
      parameters: {
        model: 'gpt-4o-mini',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.3,
        max_tokens: 10,
      },
    )

    response.dig('choices', 0, 'message', 'content').to_i
  rescue StandardError => e
    Rails.logger.warn("[EstimatePrepTimesJob] LLM failed: #{e.message}")
    nil
  end

  def estimate_heuristic(name, description, item_type)
    text = "#{name} #{description}".downcase

    return 25 if text.match?(/braise|slow.cook|confit|sous.vide/)
    return 20 if text.match?(/roast|bake|grill.*steak|well.done/)
    return 15 if text.match?(/steak|burger|pasta|risotto|curry/)
    return 12 if text.match?(/chicken|fish|seafood|stir.fry/)
    return 10 if text.match?(/pizza|sandwich|wrap|omelette/)
    return 8 if text.match?(/soup|salad.*warm|toast/)
    return 5 if text.match?(/salad|appetizer|side|dessert/)
    return 3 if text.match?(/drink|beverage|cocktail/)

    item_type == 'beverage' ? 3 : 10
  end

  def openai_client
    @openai_client ||= begin
      api_key = ENV.fetch('OPENAI_API_KEY', nil)
      api_key.present? ? OpenAI::Client.new(access_token: api_key) : nil
    end
  end
end
