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
      patch '/onboarding', params: { step: 1, user: { first_name: 'Test', last_name: 'User' } }
      expect(response).to have_http_status(:redirect)
    end
  end
end
