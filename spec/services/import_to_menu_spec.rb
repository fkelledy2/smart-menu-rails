# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportToMenu, type: :service do
  let!(:plan) { Plan.create!(status: 'active') }
  let!(:user) { User.create!(email: 'owner@example.com', password: 'password123', plan: plan) }
  let!(:restaurant) { Restaurant.create!(name: 'Test Resto', user: user, status: 'active') }

  describe '#call' do
    context 'happy path' do
      it 'creates a menu with sections and items mapped' do
        import = restaurant.ocr_menu_imports.create!(name: 'Dinner Menu', status: 'completed')

        sec1 = import.ocr_menu_sections.create!(name: 'Starters', sequence: 1, is_confirmed: true,
                                                description: 'Small plates to start',)
        sec2 = import.ocr_menu_sections.create!(name: 'Mains', sequence: 2, is_confirmed: true)

        sec1.ocr_menu_items.create!(name: 'Soup', description: 'Tomato soup', price: 4.5, sequence: 1,
                                    allergens: ['dairy'], is_confirmed: true,)
        sec1.ocr_menu_items.create!(name: 'Bread', description: 'Garlic bread', price: 3.0, sequence: 2,
                                    allergens: ['gluten'], is_confirmed: true,)
        sec2.ocr_menu_items.create!(name: 'Steak', description: 'Sirloin', price: 14.0, sequence: 1,
                                    allergens: [], is_confirmed: true,)

        menu = described_class.new(restaurant: restaurant, import: import).call

        expect(menu).to be_persisted
        expect(menu.name).to eq('Dinner Menu')
        expect(menu.menusections.order(:sequence).pluck(:name)).to eq(%w[Starters Mains])
        expect(menu.menusections.count).to eq(2)

        starters = menu.menusections.find_by(sequence: 1)
        expect(starters.menuitems.order(:sequence).pluck(:name)).to eq(%w[Soup Bread])
        soup = starters.menuitems.find_by(name: 'Soup')
        expect(soup.description).to eq('Tomato soup')
        expect(soup.price.to_f).to eq(4.5)
        expect(starters.description).to eq('Small plates to start')
      end
    end

    context 'guard rails' do
      it 'raises when import is not completed' do
        import = restaurant.ocr_menu_imports.create!(name: 'Draft', status: 'pending')
        expect do
          described_class.new(restaurant: restaurant, import: import).call
        end.to raise_error(StandardError, /not completed/i)
      end

      it 'raises when there are no confirmed sections' do
        import = restaurant.ocr_menu_imports.create!(name: 'No Sections', status: 'completed')
        import.ocr_menu_sections.create!(name: 'Temp', sequence: 1, is_confirmed: false)
        expect do
          described_class.new(restaurant: restaurant, import: import).call
        end.to raise_error(StandardError, /No confirmed sections/i)
      end

      it 'raises when a menu already exists for this import' do
        import = restaurant.ocr_menu_imports.create!(name: 'Already', status: 'completed')
        existing = restaurant.menus.create!(name: 'Existing', description: 'x', status: 'active')
        import.update!(menu: existing)
        expect do
          described_class.new(restaurant: restaurant, import: import).call
        end.to raise_error(StandardError, /already created/i)
      end
    end
  end
end
