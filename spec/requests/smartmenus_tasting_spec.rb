require 'rails_helper'

RSpec.describe 'Smartmenus tasting bundle rendering', type: :request do
  let(:restaurant) { create(:restaurant, country: 'US') }
  let(:menu) { create(:menu, restaurant: restaurant, status: 'active') }
  let(:smartmenu) { create(:smartmenu, restaurant: restaurant, menu: menu) }

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
