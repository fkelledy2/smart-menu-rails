require 'rails_helper'
require 'ostruct'

RSpec.describe 'Payments::Refunds' do
  let(:admin_user) { create(:user, admin: true) }

  let(:payment_attempt) do
    PaymentAttempt.create!(
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
  end

  let(:session_obj) { OpenStruct.new(payment_intent: OpenStruct.new(id: 'pi_test_123')) }
  let(:refund_obj) { OpenStruct.new(id: 're_test_123') }

  around do |example|
    prev = Stripe.api_key
    Stripe.api_key = 'sk_test_spec'
    example.run
  ensure
    Stripe.api_key = prev
  end

  describe 'POST /payments/refunds' do
    def post_refund
      post '/payments/refunds',
           params: { payment_attempt_id: payment_attempt.id },
           headers: { 'ACCEPT' => 'application/json' },
           as: :json
    end

    before do
      allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(session_obj)
      allow(Stripe::Refund).to receive(:create).and_return(refund_obj)
    end

    it 'creates a refund and returns ok (admin-only)' do
      sign_in admin_user

      expect { post_refund }.to change(PaymentRefund, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('ok' => true)
      expect(response.parsed_body['payment_refund_id']).to be_present
    end

    it 'persists the refund details' do
      sign_in admin_user
      post_refund

      refund = PaymentRefund.find(response.parsed_body['payment_refund_id'])
      expect(refund).to have_attributes(
        status: 'succeeded',
        provider: 'stripe',
        provider_refund_id: 're_test_123',
        amount_cents: 1000,
        currency: 'USD',
      )
    end

    it 'calls Stripe to create the refund' do
      sign_in admin_user
      post_refund

      expect(Stripe::Checkout::Session).to have_received(:retrieve)
      expect(Stripe::Refund).to have_received(:create)
    end

    it 'rejects non-admin users' do
      user = create(:user, admin: false)
      sign_in user

      post '/payments/refunds',
           params: { payment_attempt_id: payment_attempt.id },
           headers: { 'ACCEPT' => 'application/json' },
           as: :json

      expect(response).to have_http_status(:found)
    end
  end
end
