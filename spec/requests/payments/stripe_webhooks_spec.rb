require 'rails_helper'
require 'ostruct'

RSpec.describe 'Payments::Webhooks (Stripe)' do
  around do |example|
    prev = ENV.fetch('STRIPE_WEBHOOK_SECRET', nil)
    ENV['STRIPE_WEBHOOK_SECRET'] = 'whsec_test'
    example.run
  ensure
    ENV['STRIPE_WEBHOOK_SECRET'] = prev
  end

  describe 'POST /payments/webhooks/stripe' do
    let(:ordr) { create(:ordr, status: :billrequested) }
    let(:payment_attempt) do
      PaymentAttempt.create!(
        ordr: ordr,
        restaurant: create(:restaurant, currency: 'USD'),
        provider: :stripe,
        amount_cents: 1000,
        currency: 'USD',
        status: :requires_action,
        charge_pattern: :direct,
        merchant_model: :restaurant_mor,
      )
    end

    let(:payload_hash) do
      {
        id: 'evt_test_123',
        type: 'payment_intent.succeeded',
        created: Time.zone.now.to_i,
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
    end

    let(:evt_obj) do
      OpenStruct.new(
        id: 'evt_test_123',
        type: 'payment_intent.succeeded',
        created: payload_hash[:created],
        livemode: false,
        data: OpenStruct.new(
          object: OpenStruct.new(
            id: 'pi_test_123',
            metadata: { 'payment_attempt_id' => payment_attempt.id.to_s, 'order_id' => ordr.id.to_s },
          ),
        ),
      )
    end

    def post_webhook
      post '/payments/webhooks/stripe',
           params: payload_hash.to_json,
           headers: { 'HTTP_STRIPE_SIGNATURE' => 't=1,v1=fake', 'CONTENT_TYPE' => 'application/json' }
    end

    before do
      allow(Stripe::Webhook).to receive(:construct_event).and_return(evt_obj)
    end

    it 'creates a ledger event and emits order events' do
      expect { post_webhook }
        .to change(LedgerEvent, :count).by(1)
        .and change(OrderEvent, :count).by(2)
    end

    it 'marks payment_attempt succeeded and closes the order' do
      post_webhook

      payment_attempt.reload
      ordr.reload
      expect(payment_attempt.status).to eq('succeeded')
      expect(ordr.status).to eq('closed')
    end

    it 'persists expected ledger event details' do
      post_webhook

      ledger = LedgerEvent.last
      expect(ledger).to have_attributes(
        provider: 'stripe',
        provider_event_id: 'evt_test_123',
        event_type: 'succeeded',
        entity_type: 'payment_attempt',
        entity_id: payment_attempt.id,
      )
      expect(ledger.raw_event_payload).to be_a(Hash)
    end

    it 'does not create duplicate ledger events on repeat delivery' do
      post_webhook

      expect { post_webhook }.not_to change(LedgerEvent, :count)
    end

    it 'does not emit duplicate order events on repeat delivery' do
      post_webhook

      expect { post_webhook }.not_to change(OrderEvent, :count)
    end
  end
end
