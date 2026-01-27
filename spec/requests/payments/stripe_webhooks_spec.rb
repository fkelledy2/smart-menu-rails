require 'rails_helper'
require 'ostruct'

RSpec.describe 'Payments::Webhooks (Stripe)', type: :request do
  around do |example|
    prev = ENV['STRIPE_WEBHOOK_SECRET']
    ENV['STRIPE_WEBHOOK_SECRET'] = 'whsec_test'
    example.run
  ensure
    ENV['STRIPE_WEBHOOK_SECRET'] = prev
  end

  describe 'POST /payments/webhooks/stripe' do
    it 'records ledger_event idempotently and marks payment_attempt succeeded' do
      ordr = create(:ordr, status: :billrequested)
      payment_attempt = PaymentAttempt.create!(
        ordr: ordr,
        restaurant: create(:restaurant, currency: 'USD'),
        provider: :stripe,
        amount_cents: 1000,
        currency: 'USD',
        status: :requires_action,
        charge_pattern: :direct,
        merchant_model: :restaurant_mor,
      )

      created = Time.zone.now.to_i
      payload_hash = {
        id: 'evt_test_123',
        type: 'payment_intent.succeeded',
        created: created,
        data: {
          object: {
            id: 'pi_test_123',
            metadata: {
              payment_attempt_id: payment_attempt.id,
              order_id: ordr.id,
            },
          },
        },
      }
      payload = payload_hash.to_json

      evt_obj = OpenStruct.new(
        id: 'evt_test_123',
        type: 'payment_intent.succeeded',
        created: created,
        livemode: false,
        data: OpenStruct.new(
          object: OpenStruct.new(
            id: 'pi_test_123',
            metadata: { 'payment_attempt_id' => payment_attempt.id.to_s, 'order_id' => ordr.id.to_s },
          ),
        ),
      )

      allow(Stripe::Webhook).to receive(:construct_event).and_return(evt_obj)

      expect {
        post '/payments/webhooks/stripe',
             params: payload,
             headers: { 'HTTP_STRIPE_SIGNATURE' => 't=1,v1=fake', 'CONTENT_TYPE' => 'application/json' }
      }.to change(LedgerEvent, :count).by(1)
        .and change(OrderEvent, :count).by(2)

      payment_attempt.reload
      expect(payment_attempt.status).to eq('succeeded')

      ordr.reload
      expect(ordr.status).to eq('closed')

      types = OrderEvent.where(ordr_id: ordr.id).order(:sequence).pluck(:event_type)
      expect(types).to include('paid', 'closed')

      ledger = LedgerEvent.last
      expect(ledger.provider).to eq('stripe')
      expect(ledger.provider_event_id).to eq('evt_test_123')
      expect(ledger.event_type).to eq('succeeded')
      expect(ledger.entity_type).to eq('payment_attempt')
      expect(ledger.entity_id).to eq(payment_attempt.id)
      expect(ledger.raw_event_payload).to be_a(Hash)

      expect {
        post '/payments/webhooks/stripe',
             params: payload,
             headers: { 'HTTP_STRIPE_SIGNATURE' => 't=1,v1=fake', 'CONTENT_TYPE' => 'application/json' }
      }.not_to change(LedgerEvent, :count)

      expect {
        post '/payments/webhooks/stripe',
             params: payload,
             headers: { 'HTTP_STRIPE_SIGNATURE' => 't=1,v1=fake', 'CONTENT_TYPE' => 'application/json' }
      }.not_to change(OrderEvent, :count)

      payment_attempt.reload
      expect(payment_attempt.status).to eq('succeeded')

      ordr.reload
      expect(ordr.status).to eq('closed')
    end
  end
end
