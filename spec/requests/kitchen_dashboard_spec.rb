require 'rails_helper'

RSpec.describe 'KitchenDashboards' do
  describe 'GET /index' do
    it 'returns http success' do
      plan = Plan.create!(status: 'active')
      user = User.create!(email: 'kitchen@example.com', password: 'password123', plan: plan)
      restaurant = Restaurant.create!(name: 'Kitchen Resto', user: user, status: 'active')
      sign_in user

      get "/restaurants/#{restaurant.id}/kitchen"
      expect(response).to have_http_status(:success)
    end
  end
end
