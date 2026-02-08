require 'rails_helper'

RSpec.describe 'Menu publishing gating' do
  let(:plan) { create(:plan) }
  let(:user) { create(:user, plan: plan) }
  let(:restaurant) { create(:restaurant, user: user) }
  let(:menu) { create(:menu, restaurant: restaurant, status: :inactive) }

  describe 'PATCH /restaurants/:restaurant_id/menus/:id' do
    it 'rejects publishing when subscription is missing/inactive' do
      sign_in user

      patch "/restaurants/#{restaurant.id}/menus/#{menu.id}",
            params: { menu: { status: 'active' }, return_to: 'menu_edit' },
            headers: { 'ACCEPT' => 'application/json' },
            as: :json

      expect(response).to have_http_status(:unprocessable_content)
      data = response.parsed_body
      expect(data['errors'].join(' ')).to match(/Publishing requires an active subscription/i)

      expect(menu.reload.status).to eq('inactive')
    end

    it 'allows publishing when subscription is trialing with payment method' do
      sign_in user

      RestaurantSubscription.create!(
        restaurant: restaurant,
        status: :trialing,
        payment_method_on_file: true,
        stripe_customer_id: 'cus_test_123',
        stripe_subscription_id: 'sub_test_123',
      )

      patch "/restaurants/#{restaurant.id}/menus/#{menu.id}",
            params: { menu: { status: 'active' }, return_to: 'menu_edit' },
            headers: { 'ACCEPT' => 'application/json' },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(menu.reload.status).to eq('active')
    end
  end
end
