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
    it 'defines status enum correctly' do
      expect(described_class.statuses).to eq({
        'started' => 0,
        'account_created' => 1,
        'restaurant_details' => 2,
        'plan_selected' => 3,
        'menu_created' => 4,
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

    describe 'restaurant_type' do
      it 'sets and gets restaurant_type' do
        session.restaurant_type = 'casual_dining'
        expect(session.restaurant_type).to eq('casual_dining')
        expect(session.wizard_data['restaurant_type']).to eq('casual_dining')
      end
    end

    describe 'cuisine_type' do
      it 'sets and gets cuisine_type' do
        session.cuisine_type = 'italian'
        expect(session.cuisine_type).to eq('italian')
        expect(session.wizard_data['cuisine_type']).to eq('italian')
      end
    end

    describe 'location' do
      it 'sets and gets location' do
        session.location = 'New York, NY'
        expect(session.location).to eq('New York, NY')
        expect(session.wizard_data['location']).to eq('New York, NY')
      end
    end

    describe 'phone' do
      it 'sets and gets phone' do
        session.phone = '+1-555-0123'
        expect(session.phone).to eq('+1-555-0123')
        expect(session.wizard_data['phone']).to eq('+1-555-0123')
      end
    end

    describe 'selected_plan_id' do
      it 'sets and gets selected_plan_id' do
        session.selected_plan_id = 123
        expect(session.selected_plan_id).to eq(123)
        expect(session.wizard_data['selected_plan_id']).to eq(123)
      end
    end

    describe 'menu_name' do
      it 'sets and gets menu_name' do
        session.menu_name = 'Dinner Menu'
        expect(session.menu_name).to eq('Dinner Menu')
        expect(session.wizard_data['menu_name']).to eq('Dinner Menu')
      end
    end

    describe 'menu_items' do
      it 'sets and gets menu_items' do
        items = [{ 'name' => 'Pizza', 'price' => 12.99 }, { 'name' => 'Salad', 'price' => 8.99 }]
        session.menu_items = items
        expect(session.menu_items).to eq(items)
        expect(session.wizard_data['menu_items']).to eq(items)
      end

      it 'returns empty array when not set' do
        expect(session.menu_items).to eq([])
      end
    end

    it 'preserves existing wizard_data when setting new values' do
      session.restaurant_name = 'Test Restaurant'
      session.cuisine_type = 'italian'

      expect(session.wizard_data).to eq({
        'restaurant_name' => 'Test Restaurant',
        'cuisine_type' => 'italian',
      })
    end
  end

  describe '#progress_percentage' do
    it 'calculates correct percentage for each status' do
      session = described_class.new

      session.status = 'started'
      expect(session.progress_percentage).to eq(20)

      session.status = 'account_created'
      expect(session.progress_percentage).to eq(40)

      session.status = 'restaurant_details'
      expect(session.progress_percentage).to eq(60)

      session.status = 'plan_selected'
      expect(session.progress_percentage).to eq(80)

      session.status = 'menu_created'
      expect(session.progress_percentage).to eq(100)

      session.status = 'completed'
      expect(session.progress_percentage).to eq(120)
    end
  end

  describe '#step_valid?' do
    let(:session) { described_class.new(user: user) }

    context 'step 1 (account creation)' do
      it 'returns true when user has name and email' do
        user.update!(name: 'John Doe', email: 'john@example.com')
        expect(session.step_valid?(1)).to be true
      end

      it 'returns false when user lacks name' do
        user.update_columns(first_name: nil, last_name: nil)
        expect(session.step_valid?(1)).to be false
      end

      it 'returns false when user lacks email' do
        # Create a new user without email to test validation
        user_without_email = User.new(first_name: 'John', last_name: 'Doe')
        session.user = user_without_email
        expect(session.step_valid?(1)).to be false
      end

      it 'returns false when no user' do
        session.user = nil
        expect(session.step_valid?(1)).to be false
      end
    end

    context 'step 2 (restaurant details)' do
      it 'returns true when all restaurant details are present' do
        session.restaurant_name = 'Test Restaurant'
        session.restaurant_type = 'casual_dining'
        session.cuisine_type = 'italian'
        expect(session.step_valid?(2)).to be true
      end

      it 'returns false when restaurant_name is missing' do
        session.restaurant_type = 'casual_dining'
        session.cuisine_type = 'italian'
        expect(session.step_valid?(2)).to be false
      end

      it 'returns false when restaurant_type is missing' do
        session.restaurant_name = 'Test Restaurant'
        session.cuisine_type = 'italian'
        expect(session.step_valid?(2)).to be false
      end

      it 'returns false when cuisine_type is missing' do
        session.restaurant_name = 'Test Restaurant'
        session.restaurant_type = 'casual_dining'
        expect(session.step_valid?(2)).to be false
      end
    end

    context 'step 3 (plan selection)' do
      it 'returns true when plan is selected' do
        session.selected_plan_id = 123
        expect(session.step_valid?(3)).to be true
      end

      it 'returns false when no plan is selected' do
        expect(session.step_valid?(3)).to be false
      end
    end

    context 'step 4 (menu creation)' do
      it 'returns true when menu name and items are present' do
        session.menu_name = 'Dinner Menu'
        session.menu_items = [{ 'name' => 'Pizza', 'price' => 12.99 }]
        expect(session.step_valid?(4)).to be true
      end

      it 'returns false when menu_name is missing' do
        session.menu_items = [{ 'name' => 'Pizza', 'price' => 12.99 }]
        expect(session.step_valid?(4)).to be false
      end

      it 'returns false when menu_items are empty' do
        session.menu_name = 'Dinner Menu'
        session.menu_items = []
        expect(session.step_valid?(4)).to be false
      end
    end

    context 'unknown step' do
      it 'returns true for unknown steps' do
        expect(session.step_valid?(99)).to be true
      end
    end
  end

  describe 'IdentityCache integration' do
    it 'has cache indexes configured' do
      # Test that the model has IdentityCache included
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
