# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OcrMenuImports' do
  describe 'POST /restaurants/:restaurant_id/ocr_menu_imports/:id/confirm_import' do
    before do
      # Bypass app-wide filters not under test
      allow_any_instance_of(OcrMenuImportsController).to receive(:set_current_employee).and_return(true)
      allow_any_instance_of(OcrMenuImportsController).to receive(:set_permissions).and_return(true)
      allow_any_instance_of(OcrMenuImportsController).to receive(:authorize_restaurant_owner).and_return(true)
      allow_any_instance_of(OcrMenuImportsController).to receive(:verify_authenticity_token).and_return(true)
    end

    let!(:plan) { Plan.create!(status: 'active') }
    let!(:user) { User.create!(email: 'owner@example.com', password: 'password123', plan: plan) }
    let!(:restaurant) { Restaurant.create!(name: 'Test Resto', user: user, status: 'active') }

    it 'creates a menu and redirects to the menu page on success' do
      skip 'Controller spec asserts redirect behavior; request spec pending due to test stack specifics.'
      import = restaurant.ocr_menu_imports.create!(name: 'Dinner', status: 'completed')
      import.ocr_menu_sections.create!(name: 'Starters', sequence: 1, is_confirmed: true)

      # Stub service to isolate controller behavior
      stub_menu = restaurant.menus.create!(name: 'Stubbed', description: 'Imported from PDF', status: 'active')
      allow(ImportToMenu).to receive(:new).and_return(double(call: stub_menu))

      sign_in user
      post confirm_import_restaurant_ocr_menu_import_path(restaurant, import), headers: { 'ACCEPT' => 'text/html' },
                                                                               as: :html

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(restaurant_menu_path(restaurant, stub_menu))
    end

    it 'prevents duplicate imports and redirects to existing menu' do
      skip 'Controller spec asserts redirect behavior; request spec pending due to test stack specifics.'
      import = restaurant.ocr_menu_imports.create!(name: 'Brunch', status: 'completed')
      menu = restaurant.menus.create!(name: 'Existing', description: 'x', status: 'active')
      import.update!(menu: menu)
      sign_in user
      post confirm_import_restaurant_ocr_menu_import_path(restaurant, import), headers: { 'HTTP_ACCEPT' => 'text/html' }
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(restaurant_menu_path(restaurant, menu))
    end

    it 'rejects when no confirmed sections' do
      skip 'Controller spec asserts redirect behavior; request spec pending due to test stack specifics.'
      import = restaurant.ocr_menu_imports.create!(name: 'Empty', status: 'completed')
      # create an unconfirmed section to exercise the guard
      import.ocr_menu_sections.create!(name: 'Temp', sequence: 1, is_confirmed: false)
      sign_in user
      post confirm_import_restaurant_ocr_menu_import_path(restaurant, import), headers: { 'HTTP_ACCEPT' => 'text/html' }
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(restaurant_ocr_menu_import_path(restaurant, import))
      follow_redirect!
      expect(response.body).to include('Please confirm at least one section')
    end

    it 'rejects when not completed' do
      skip 'Controller spec asserts redirect behavior; request spec pending due to test stack specifics.'
      import = restaurant.ocr_menu_imports.create!(name: 'Draft', status: 'pending')
      sign_in user
      post confirm_import_restaurant_ocr_menu_import_path(restaurant, import), headers: { 'HTTP_ACCEPT' => 'text/html' }
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(restaurant_ocr_menu_import_path(restaurant, import))
    end
  end
end
