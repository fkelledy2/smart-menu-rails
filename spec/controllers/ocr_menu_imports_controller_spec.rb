# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OcrMenuImportsController do
  render_views false

  let!(:plan) { Plan.create!(status: 'active') }
  let!(:user) { User.create!(email: 'owner@example.com', password: 'password123', plan: plan) }
  let!(:restaurant) { Restaurant.create!(name: 'Test Resto', user: user, status: 'active') }

  before do
    # Devise mapping for controller specs
    @request.env['devise.mapping'] = Devise.mappings[:user]
    @request.headers['ACCEPT'] = 'text/html'
    # Bypass app-wide filters not under test
    allow(controller).to receive_messages(set_current_employee: true, set_permissions: true,
                                          verify_authenticity_token: true,)
    # Mock authorization to always pass
    allow(controller).to receive(:authorize).and_return(true)
    # Auth
    sign_in user
  end

  describe 'POST #confirm_import' do
    it 'processes confirm import action' do
      import = restaurant.ocr_menu_imports.create!(name: 'Dinner', status: 'completed')
      import.ocr_menu_sections.create!(name: 'Starters', sequence: 1, is_confirmed: true)

      post :confirm_import, params: { restaurant_id: restaurant.id, id: import.id }

      expect(response).to have_http_status(:found)
    end

    it 'handles case when no confirmed sections' do
      import = restaurant.ocr_menu_imports.create!(name: 'Empty', status: 'completed')
      post :confirm_import, params: { restaurant_id: restaurant.id, id: import.id }
      expect(response).to have_http_status(:found)
    end

    it 'handles existing menu case' do
      import = restaurant.ocr_menu_imports.create!(name: 'Brunch', status: 'completed')
      menu = restaurant.menus.create!(name: 'Existing', description: 'x', status: 'active')
      import.update!(menu: menu)

      post :confirm_import, params: { restaurant_id: restaurant.id, id: import.id }
      expect(response).to have_http_status(:found)
    end
  end
end
