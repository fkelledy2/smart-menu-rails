require 'rails_helper'

RSpec.describe 'Onboardings' do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET /onboarding' do
    it 'returns http success' do
      get '/onboarding'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /onboarding' do
    it 'processes onboarding update' do
      patch '/onboarding', params: {
        step: 1,
        user: { name: 'Test User' },
        onboarding_session: { restaurant_name: 'Test Restaurant' },
      }
      expect(response).to have_http_status(:see_other)
    end
  end
end
