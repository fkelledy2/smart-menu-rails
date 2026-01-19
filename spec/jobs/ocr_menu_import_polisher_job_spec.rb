require 'rails_helper'

RSpec.describe OcrMenuImportPolisherJob do
  it 'uses restaurant default locale for LLM prompts' do
    restaurant = create(:restaurant)
    Restaurantlocale.create!(restaurant: restaurant, locale: 'IT', status: 'active', dfault: true)

    import = create(:ocr_menu_import, :completed, restaurant: restaurant)
    section = create(:ocr_menu_section, ocr_menu_import: import, name: 'Bevande', description: 'Acqua e bibite')
    create(:ocr_menu_item, ocr_menu_section: section, name: 'Acqua', description: 'Acqua', image_prompt: nil)

    calls = []
    client = double('OpenAIClient')
    allow(client).to receive(:chat) do |parameters:|
      calls << parameters
      { 'choices' => [{ 'message' => { 'content' => 'Test output' } }] }
    end

    redis = double('redis')
    allow(redis).to receive(:setex)
    allow(redis).to receive(:get).and_return(nil)
    allow(Sidekiq).to receive(:redis).and_yield(redis)

    prev_client = Rails.configuration.x.openai_client
    Rails.configuration.x.openai_client = client

    described_class.new.perform(import.id)

    system_messages = calls.map { |p| p.dig(:messages, 0, :content).to_s }
    expect(system_messages.any? { |m| m.include?('Write in Italian') }).to be(true)
  ensure
    Rails.configuration.x.openai_client = prev_client
  end
end
