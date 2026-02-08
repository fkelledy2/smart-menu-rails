require 'rails_helper'

RSpec.describe 'Payments::Subscriptions' do
  let(:plan) { create(:plan, stripe_price_id_month: 'price_month_test_123', stripe_price_id_year: 'price_year_test_123') }
  let(:user) { create(:user, plan: plan) }
  let(:restaurant) { create(:restaurant, user: user, currency: 'USD') }

  around do |example|
    prev = Stripe.api_key
    Stripe.api_key = 'sk_test_spec'
    example.run
  ensure
    Stripe.api_key = prev
  end

  describe 'POST /payments/subscriptions/start' do
    it 'returns checkout_url and persists stripe_customer_id on the restaurant subscription' do
      sign_in user

      fake_customer = Struct.new(:id).new('cus_test_123')
      fake_session = Struct.new(:url).new('https://stripe.test/subscription_checkout')

      allow(Stripe::Customer).to receive(:create).and_return(fake_customer)
      allow(Stripe::Checkout::Session).to receive(:create).and_return(fake_session)

      post '/payments/subscriptions/start',
           params: { restaurant_id: restaurant.id, interval: 'month', success_url: 'https://example.test/success', cancel_url: 'https://example.test/cancel' },
           headers: { 'ACCEPT' => 'application/json' },
           as: :json

      expect(response).to have_http_status(:ok)
      data = response.parsed_body
      expect(data['ok']).to be(true)
      expect(data['checkout_url']).to eq('https://stripe.test/subscription_checkout')

      rs = restaurant.reload.restaurant_subscription
      expect(rs).to be_present
      expect(rs.stripe_customer_id).to eq('cus_test_123')

      expect(Stripe::Checkout::Session).to have_received(:create) do |args|
        expect(args[:mode]).to eq('subscription')
        expect(args[:customer]).to eq('cus_test_123')
        expect(args[:line_items]).to eq([{ price: 'price_month_test_123', quantity: 1 }])
        expect(args[:metadata][:restaurant_id]).to eq(restaurant.id.to_s)
      end
    end

    it 'returns 422 when plan is missing Stripe price id for the interval' do
      sign_in user
      user.plan.update!(stripe_price_id_month: nil)

      post '/payments/subscriptions/start',
           params: { restaurant_id: restaurant.id, interval: 'month' },
           headers: { 'ACCEPT' => 'application/json' },
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      data = response.parsed_body
      expect(data['ok']).to be(false)
    end
  end
end
