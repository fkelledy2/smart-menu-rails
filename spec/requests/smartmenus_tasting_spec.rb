require 'rails_helper'

RSpec.describe 'Smartmenus tasting bundle rendering', type: :request do
  let(:restaurant) { create(:restaurant, country: 'US') }
  let(:menu) { create(:menu, restaurant: restaurant, status: 'active') }
  let(:smartmenu) { create(:smartmenu, restaurant: restaurant, menu: menu) }

  describe 'locale rendering' do
    it 'renders localized menu item names for ?locale=it and cache varies by locale' do
      # Ensure Italian is an active (non-default) locale for this restaurant
      Restaurantlocale.create!(restaurant: restaurant, locale: 'en', status: :active, dfault: true)
      Restaurantlocale.create!(restaurant: restaurant, locale: 'it', status: :active, dfault: false)

      section = create(:menusection, menu: menu, name: 'Starters')
      item = create(:menuitem, menusection: section, name: 'Water')
      Menuitemlocale.create!(menuitem: item, locale: 'it', name: 'Acqua', description: 'Acqua')

      # Exercise the cached branches in the view (cache is disabled in test env by default).
      allow(Rails.env).to receive(:test?).and_return(false)

      # Enable caching in controller/view layer and ensure a clean cache.
      old_perform_caching = ActionController::Base.perform_caching
      ActionController::Base.perform_caching = true
      Rails.cache.clear

      begin
        get "/smartmenus/#{smartmenu.slug}", params: { view: 'customer', locale: 'it' }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Acqua')

        get "/smartmenus/#{smartmenu.slug}", params: { view: 'customer', locale: 'en' }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Water')
      ensure
        ActionController::Base.perform_caching = old_perform_caching
      end
    end
  end

  describe 'customer view' do
    it 'renders tasting bundle CTA and meta when section is tasting' do
      section = create(:menusection, :tasting, menu: menu, name: 'The Chef Recommends - TASTING MENU')
      carrier = create(:menuitem, :carrier, menusection: section, name: 'Carrier Item')
      create(:menuitem, menusection: section, name: 'Included Course')

      get "/smartmenus/#{smartmenu.slug}", params: { view: 'customer' }
      expect(response).to have_http_status(:ok)

      body = response.body
      expect(body).to include('data-tasting-meta=')
      expect(body).to include('Add Tasting Menu')
      # Ensure carrier id is present in the tasting metadata JSON
      expect(body).to include("\"carrier_id\":#{carrier.id}")
    end
  end

  describe 'staff view' do
    it 'renders Show courses toggle for tasting sections' do
      section = create(:menusection, :tasting, menu: menu, name: 'The Chef Recommends - TASTING MENU')
      create(:menuitem, :carrier, menusection: section)
      create(:menuitem, menusection: section)

      get "/smartmenus/#{smartmenu.slug}", params: { view: 'staff' }
      expect(response).to have_http_status(:ok)

      body = response.body
      expect(body).to include('Show courses')
      expect(body).to include('Add Tasting Menu')
    end
  end
end
