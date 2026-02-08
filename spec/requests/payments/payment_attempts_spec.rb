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
    let(:fake_session) do
      Struct.new(:id, :url, :payment_intent).new('cs_test_123', 'https://stripe.test/checkout', 'pi_test_123')
    end

    def request_params
      { ordr_id: ordr.id, success_url: 'https://example.test/success', cancel_url: 'https://example.test/cancel' }
    end

    def post_create_attempt
      post '/payments/payment_attempts',
           params: request_params,
           headers: { 'ACCEPT' => 'application/json' },
           as: :json
    end

    before do
      allow(Stripe::Checkout::Session).to receive(:create).and_return(fake_session)
    end

    it 'returns ok payload and redirect_url' do
      post_create_attempt

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'ok' => true,
        'redirect_url' => 'https://stripe.test/checkout',
      )
      expect(response.parsed_body['payment_attempt_id']).to be_present
    end

    it 'persists a payment_attempt for the order' do
      post_create_attempt

      payment_attempt_id = response.parsed_body['payment_attempt_id']
      payment_attempt = PaymentAttempt.find(payment_attempt_id)
      expect(payment_attempt).to have_attributes(
        provider: 'stripe',
        status: 'requires_action',
        currency: 'USD',
        amount_cents: 1000,
        provider_payment_id: 'cs_test_123',
      )
    end

    it 'creates a payment_profile for the restaurant' do
      post_create_attempt

      profile = PaymentProfile.find_by(restaurant: restaurant)
      expect(profile).to have_attributes(
        merchant_model: 'restaurant_mor',
        primary_provider: 'stripe',
      )
    end

    it 'sends order metadata to Stripe checkout session create' do
      post_create_attempt

      payment_attempt_id = response.parsed_body['payment_attempt_id']
      payment_attempt = PaymentAttempt.find(payment_attempt_id)

      expect(Stripe::Checkout::Session).to have_received(:create) do |args|
        md = args[:metadata]
        expect(md).to include(
          order_id: ordr.id,
          restaurant_id: restaurant.id,
          payment_attempt_id: payment_attempt.id,
        )
      end
    end
  end
end
