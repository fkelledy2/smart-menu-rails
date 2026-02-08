require 'rails_helper'

RSpec.describe 'Payments::PaymentAttempts' do
  let(:restaurant) { create(:restaurant, currency: 'USD') }
  let(:menu) { create(:menu, restaurant: restaurant) }
  let(:tablesetting) { create(:tablesetting, restaurant: restaurant) }
  let(:ordr) do
    create(
      :ordr,
      restaurant: restaurant,
      menu: menu,
      tablesetting: tablesetting,
      gross: 12.0,
      tip: 2.0,
      status: :billrequested,
    )
  end

  around do |example|
    prev = Stripe.api_key
    Stripe.api_key = 'sk_test_spec'
    example.run
  ensure
    Stripe.api_key = prev
  end

  describe 'POST /payments/payment_attempts' do
    it 'creates a payment_attempt and returns redirect_url' do
      fake_session = Struct.new(:id, :url, :payment_intent).new('cs_test_123', 'https://stripe.test/checkout', 'pi_test_123')
      allow(Stripe::Checkout::Session).to receive(:create).and_return(fake_session)

      post '/payments/payment_attempts',
           params: { ordr_id: ordr.id, success_url: 'https://example.test/success', cancel_url: 'https://example.test/cancel' },
           headers: { 'ACCEPT' => 'application/json' },
           as: :json

      expect(response).to have_http_status(:ok)
      data = response.parsed_body
      expect(data['ok']).to be(true)
      expect(data['payment_attempt_id']).to be_present
      expect(data['redirect_url']).to eq('https://stripe.test/checkout')

      payment_attempt = PaymentAttempt.find(data['payment_attempt_id'])
      expect(payment_attempt.provider).to eq('stripe')
      expect(payment_attempt.status).to eq('requires_action')
      expect(payment_attempt.currency).to eq('USD')
      expect(payment_attempt.amount_cents).to eq(1000)
      expect(payment_attempt.provider_payment_id).to eq('cs_test_123')

      profile = PaymentProfile.find_by(restaurant: restaurant)
      expect(profile).to be_present
      expect(profile.merchant_model).to eq('restaurant_mor')
      expect(profile.primary_provider).to eq('stripe')

      expect(Stripe::Checkout::Session).to have_received(:create) do |args|
        md = args[:metadata]
        expect(md[:order_id]).to eq(ordr.id)
        expect(md[:restaurant_id]).to eq(restaurant.id)
        expect(md[:payment_attempt_id]).to eq(payment_attempt.id)
      end
    end
  end
end
