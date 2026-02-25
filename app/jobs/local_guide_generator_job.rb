# frozen_string_literal: true

# Generates or regenerates AI-powered local guides grounded in real restaurant data.
# Always creates guides as draft — requires admin approval before publishing.
class LocalGuideGeneratorJob < ApplicationJob
  queue_as :default

  def perform(local_guide_id: nil, city: nil, category: nil)
    if local_guide_id
      guide = LocalGuide.find(local_guide_id)
      regenerate_guide(guide)
    else
      generate_new_guide(city: city, category: category)
    end
  end

  private

  def generate_new_guide(city:, category:)
    restaurants = fetch_restaurants(city, category)
    return if restaurants.empty?

    prompt = build_prompt(city, category, restaurants)
    response = call_openai(prompt)

    LocalGuide.create!(
      title: "#{category&.titleize || 'Best'} Restaurants in #{city}",
      city: city,
      country: infer_country(city),
      category: category,
      content: response[:content],
      content_source: response[:raw],
      referenced_restaurants: build_references(restaurants),
      faq_data: response[:faq] || [],
      status: :draft,
      regenerated_at: Time.current,
    )
  end

  def regenerate_guide(guide)
    restaurants = fetch_restaurants(guide.city, guide.category)
    prompt = build_prompt(guide.city, guide.category, restaurants)
    response = call_openai(prompt)

    guide.update!(
      content: response[:content],
      content_source: response[:raw],
      referenced_restaurants: build_references(restaurants),
      faq_data: response[:faq] || [],
      regenerated_at: Time.current,
      status: :draft,
    )
  end

  def fetch_restaurants(city, category)
    scope = Restaurant.where(preview_enabled: true)
      .where('LOWER(city) = ?', city.downcase)
      .includes(menus: { menusections: :menuitems })
    if category.present?
      scope = scope.where('? = ANY(establishment_types)', category)
    end
    scope.limit(20)
  end

  def build_prompt(city, category, restaurants)
    restaurant_data = restaurants.map do |r|
      items = r.menus.flat_map { |m| m.menusections.flat_map(&:menuitems) }
        .select { |i| i.try(:active?) }
        .first(10)
      {
        name: r.name,
        description: r.description,
        items: items.map { |i| { name: i.name, description: i.description, price: i.price } },
      }
    end

    <<~PROMPT
      Write a concise, informative local guide about #{category || 'dining'} in #{city}.

      Ground every recommendation in the following real restaurant data. Do not invent
      restaurants or dishes. Reference specific dish names and prices where relevant.

      Restaurant data:
      #{JSON.pretty_generate(restaurant_data)}

      Requirements:
      - 400-600 words
      - Include 3-5 specific dish recommendations with prices
      - Include 3 FAQ questions and answers (JSON array: [{question, answer}])
      - Professional tone, useful for tourists and locals
      - Output format: JSON with keys "content" (HTML string) and "faq" (array)
    PROMPT
  end

  def call_openai(prompt)
    client = OpenAI::Client.new
    response = client.chat(parameters: {
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'You are a knowledgeable local food guide writer.' },
        { role: 'user', content: prompt },
      ],
      temperature: 0.7,
    })
    raw = response.dig('choices', 0, 'message', 'content')
    parsed = JSON.parse(raw)
    { content: parsed['content'], faq: parsed['faq'], raw: raw }
  rescue JSON::ParserError
    { content: raw, faq: [], raw: raw }
  end

  def build_references(restaurants)
    restaurants.map do |r|
      {
        id: r.id,
        name: r.name,
        menuitem_ids: r.menus.flat_map do |m|
          m.menusections.flat_map { |s| s.menuitems.map(&:id) }
        end.first(20),
      }
    end
  end

  def infer_country(city)
    Restaurant.where('LOWER(city) = ?', city.downcase)
      .where.not(country: [nil, ''])
      .limit(1).pick(:country) || 'Unknown'
  end
end
