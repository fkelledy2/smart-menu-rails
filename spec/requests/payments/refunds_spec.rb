require 'rails_helper'
require 'ostruct'

RSpec.describe 'Payments::Refunds' do
  let(:admin_user) { create(:user, admin: true) }

  around do |example|
    prev = Stripe.api_key
    Stripe.api_key = 'sk_test_spec'
    example.run
  ensure
    Stripe.api_key = prev
  end

  describe 'POST /payments/refunds' do
    it 'creates a full refund (admin-only)' do
      sign_in admin_user

      payment_attempt = PaymentAttempt.create!(
        ordr: create(:ordr, status: :billrequested),
        restaurant: create(:restaurant, currency: 'USD'),
        provider: :stripe,
        provider_payment_id: 'cs_test_123',
        amount_cents: 1000,
        currency: 'USD',
        status: :succeeded,
        charge_pattern: :direct,
        merchant_model: :restaurant_mor,
      )

      session = OpenStruct.new(payment_intent: OpenStruct.new(id: 'pi_test_123'))
      refund_obj = OpenStruct.new(id: 're_test_123')

      allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(session)
      allow(Stripe::Refund).to receive(:create).and_return(refund_obj)

      expect do
        post '/payments/refunds',
             params: { payment_attempt_id: payment_attempt.id },
             headers: { 'ACCEPT' => 'application/json' },
             as: :json
      end.to change(PaymentRefund, :count).by(1)

      data = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(data['ok']).to be(true)

      refund = PaymentRefund.find(data['payment_refund_id'])
      expect(refund.status).to eq('succeeded')
      expect(refund.provider).to eq('stripe')
      expect(refund.provider_refund_id).to eq('re_test_123')
      expect(refund.amount_cents).to eq(1000)
      expect(refund.currency).to eq('USD')

      expect(Stripe::Checkout::Session).to have_received(:retrieve)
      expect(Stripe::Refund).to have_received(:create)
    end

    it 'rejects non-admin users' do
      user = create(:user, admin: false)
      sign_in user

      payment_attempt = PaymentAttempt.create!(
        ordr: create(:ordr, status: :billrequested),
        restaurant: create(:restaurant, currency: 'USD'),
        provider: :stripe,
        provider_payment_id: 'cs_test_123',
        amount_cents: 1000,
        currency: 'USD',
        status: :succeeded,
        charge_pattern: :direct,
        merchant_model: :restaurant_mor,
      )

      post '/payments/refunds',
           params: { payment_attempt_id: payment_attempt.id },
           headers: { 'ACCEPT' => 'application/json' },
           as: :json

      expect(response).to have_http_status(:found)
    end
  end
end
