require 'rails_helper'

RSpec.describe OnboardingSession do
  let(:user) { create(:user) }
  let(:restaurant) { create(:restaurant, user: user) }
  let(:menu) { create(:menu, restaurant: restaurant) }
  let(:onboarding_session) { create(:onboarding_session, user: user) }

  describe 'associations' do
    it 'belongs to user optionally' do
      session = described_class.new
      expect(session.user).to be_nil
      session.user = user
      expect(session.user).to eq(user)
    end

    it 'belongs to restaurant optionally' do
      session = described_class.new
      expect(session.restaurant).to be_nil
      session.restaurant = restaurant
      expect(session.restaurant).to eq(restaurant)
    end

    it 'belongs to menu optionally' do
      session = described_class.new
      expect(session.menu).to be_nil
      session.menu = menu
      expect(session.menu).to eq(menu)
    end
  end

  describe 'enums' do
    it 'defines simplified status enum (started → completed)' do
      expect(described_class.statuses).to eq({
        'started' => 0,
        'completed' => 5,
      })
    end
  end

  describe 'wizard data accessors' do
    let(:session) { described_class.new }

    describe 'restaurant_name' do
      it 'sets and gets restaurant_name' do
        session.restaurant_name = 'Test Restaurant'
        expect(session.restaurant_name).to eq('Test Restaurant')
        expect(session.wizard_data['restaurant_name']).to eq('Test Restaurant')
      end

      it 'returns nil when not set' do
        expect(session.restaurant_name).to be_nil
      end
    end

    it 'preserves existing wizard_data when setting restaurant_name' do
      session.wizard_data = { 'legacy_key' => 'value' }
      session.restaurant_name = 'Test Restaurant'

      expect(session.wizard_data['restaurant_name']).to eq('Test Restaurant')
      expect(session.wizard_data['legacy_key']).to eq('value')
    end
  end

  describe '#progress_percentage' do
    it 'returns 0 when started' do
      session = described_class.new(status: 'started')
      expect(session.progress_percentage).to eq(0)
    end

    it 'returns 100 when completed' do
      session = described_class.new(status: 'completed')
      expect(session.progress_percentage).to eq(100)
    end
  end

  describe 'serialization' do
    it 'serializes wizard_data as JSON' do
      session = described_class.new
      session.wizard_data = { 'restaurant_name' => 'Test' }
      expect(session.wizard_data).to eq({ 'restaurant_name' => 'Test' })
    end
  end

  describe 'IdentityCache integration' do
    it 'has cache indexes configured' do
      expect(described_class.included_modules).to include(IdentityCache)
    end

    it 'can be found by id' do
      session = create(:onboarding_session)
      found_session = described_class.find(session.id)
      expect(found_session).to eq(session)
    end

    it 'can be found by user_id' do
      session = create(:onboarding_session, user: user)
      found_sessions = described_class.where(user_id: user.id)
      expect(found_sessions).to include(session)
    end

    it 'can be found by status' do
      session = create(:onboarding_session, status: 'started')
      found_sessions = described_class.where(status: 'started')
      expect(found_sessions).to include(session)
    end
  end
end
