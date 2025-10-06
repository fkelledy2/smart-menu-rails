require 'rails_helper'

RSpec.describe OnboardingHelper, type: :helper do
  describe '#onboarding_step_title' do
    it 'returns correct title for step 1' do
      expect(helper.onboarding_step_title('1')).to eq('Restaurant Information')
      expect(helper.onboarding_step_title('restaurant')).to eq('Restaurant Information')
    end

    it 'returns correct title for step 2' do
      expect(helper.onboarding_step_title('2')).to eq('Menu Setup')
      expect(helper.onboarding_step_title('menu')).to eq('Menu Setup')
    end

    it 'returns correct title for step 3' do
      expect(helper.onboarding_step_title('3')).to eq('Payment Configuration')
      expect(helper.onboarding_step_title('payment')).to eq('Payment Configuration')
    end

    it 'returns correct title for step 4' do
      expect(helper.onboarding_step_title('4')).to eq('Setup Complete')
      expect(helper.onboarding_step_title('complete')).to eq('Setup Complete')
    end

    it 'returns default title for unknown step' do
      expect(helper.onboarding_step_title('unknown')).to eq('Onboarding')
      expect(helper.onboarding_step_title(nil)).to eq('Onboarding')
    end
  end

  describe '#onboarding_progress_percentage' do
    it 'returns correct percentage for each step' do
      expect(helper.onboarding_progress_percentage('1')).to eq(25)
      expect(helper.onboarding_progress_percentage('restaurant')).to eq(25)
      expect(helper.onboarding_progress_percentage('2')).to eq(50)
      expect(helper.onboarding_progress_percentage('menu')).to eq(50)
      expect(helper.onboarding_progress_percentage('3')).to eq(75)
      expect(helper.onboarding_progress_percentage('payment')).to eq(75)
      expect(helper.onboarding_progress_percentage('4')).to eq(100)
      expect(helper.onboarding_progress_percentage('complete')).to eq(100)
    end

    it 'returns 0 for unknown step' do
      expect(helper.onboarding_progress_percentage('unknown')).to eq(0)
      expect(helper.onboarding_progress_percentage(nil)).to eq(0)
    end
  end

  describe '#onboarding_step_completed?' do
    let(:user) { create(:user) }

    context 'when user is nil' do
      it 'returns false' do
        expect(helper.onboarding_step_completed?('1', nil)).to be false
      end
    end

    context 'for restaurant step' do
      it 'returns true when user has restaurants' do
        create(:restaurant, user: user)
        expect(helper.onboarding_step_completed?('1', user)).to be true
        expect(helper.onboarding_step_completed?('restaurant', user)).to be true
      end

      it 'returns false when user has no restaurants' do
        expect(helper.onboarding_step_completed?('1', user)).to be false
      end
    end

    context 'for menu step' do
      it 'returns true when user has restaurants with menus' do
        restaurant = create(:restaurant, user: user)
        create(:menu, restaurant: restaurant)
        expect(helper.onboarding_step_completed?('2', user)).to be true
        expect(helper.onboarding_step_completed?('menu', user)).to be true
      end

      it 'returns false when user has restaurants but no menus' do
        create(:restaurant, user: user)
        expect(helper.onboarding_step_completed?('2', user)).to be false
      end
    end

    context 'for payment step' do
      it 'returns true when user has active restaurants' do
        create(:restaurant, user: user, status: 'active')
        expect(helper.onboarding_step_completed?('3', user)).to be true
        expect(helper.onboarding_step_completed?('payment', user)).to be true
      end

      it 'returns false when user has no active restaurants' do
        create(:restaurant, user: user, status: 'inactive')
        expect(helper.onboarding_step_completed?('3', user)).to be false
      end
    end

    it 'returns false for unknown steps' do
      expect(helper.onboarding_step_completed?('unknown', user)).to be false
    end
  end

  describe '#next_onboarding_step' do
    it 'returns correct next step' do
      expect(helper.next_onboarding_step('1')).to eq('2')
      expect(helper.next_onboarding_step('restaurant')).to eq('2')
      expect(helper.next_onboarding_step('2')).to eq('3')
      expect(helper.next_onboarding_step('menu')).to eq('3')
      expect(helper.next_onboarding_step('3')).to eq('4')
      expect(helper.next_onboarding_step('payment')).to eq('4')
    end

    it 'returns step 1 for unknown or final steps' do
      expect(helper.next_onboarding_step('4')).to eq('1')
      expect(helper.next_onboarding_step('complete')).to eq('1')
      expect(helper.next_onboarding_step('unknown')).to eq('1')
      expect(helper.next_onboarding_step(nil)).to eq('1')
    end
  end
end
