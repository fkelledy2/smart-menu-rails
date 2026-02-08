require 'rails_helper'

RSpec.describe AiMenuPolisherJob do
  it 'uses restaurant default locale for LLM prompts' do
    restaurant = create(:restaurant)
    Restaurantlocale.create!(restaurant: restaurant, locale: 'IT', status: 'active', dfault: true)

    menu = create(:menu, restaurant: restaurant)
    section = create(:menusection, menu: menu)
    create(:menuitem, menusection: section, name: 'Acqua', description: 'Acqua', image_prompt: nil)

    calls = []
    client = double('OpenAIClient')
    allow(client).to receive(:chat) do |parameters:|
      calls << parameters
      { 'choices' => [{ 'message' => { 'content' => 'Test output' } }] }
    end

    prev_client = Rails.configuration.x.openai_client
    Rails.configuration.x.openai_client = client

    allow(AlcoholDetectionService).to receive(:detect).and_return({ decided: false, confidence: 0.0 })
    allow(AdvancedCacheService).to receive(:invalidate_menu_caches)
    allow(AdvancedCacheService).to receive(:invalidate_restaurant_caches)
    allow_any_instance_of(described_class).to receive(:set_progress)

    described_class.new.perform(menu.id)

    system_messages = calls.map { |p| p.dig(:messages, 0, :content).to_s }
    expect(system_messages.any? { |m| m.include?('Write in Italian') }).to be(true)
  ensure
    Rails.configuration.x.openai_client = prev_client
  end
end
