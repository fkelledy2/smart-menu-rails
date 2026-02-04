require 'rails_helper'

RSpec.describe Plan, type: :model do
  describe 'stripe price id validation' do
    it 'requires stripe_price_id_month for active register plans' do
      plan = build(:plan, status: :active, action: :register, stripe_price_id_month: nil)
      expect(plan).not_to be_valid
      expect(plan.errors[:stripe_price_id_month]).to be_present
    end

    it 'does not require stripe_price_id_month for call plans' do
      plan = build(:plan, status: :active, action: :call, stripe_price_id_month: nil)
      expect(plan).to be_valid
    end

    it 'does not require stripe_price_id_month for inactive plans' do
      plan = build(:plan, status: :inactive, action: :register, stripe_price_id_month: nil)
      expect(plan).to be_valid
    end
  end
end
