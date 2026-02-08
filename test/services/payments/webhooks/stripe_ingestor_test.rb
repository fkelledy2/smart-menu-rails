require 'test_helper'

class Payments::Webhooks::StripeIngestorTest < ActiveSupport::TestCase
  test 'records refund events and updates payment_refund status' do
    ordr = ordrs(:one)

    payment_attempt = PaymentAttempt.create!(
      ordr: ordr,
      restaurant: ordr.restaurant,
      provider: :stripe,
      provider_payment_id: 'cs_test_123',
      amount_cents: 1000,
      currency: 'USD',
      status: :succeeded,
      charge_pattern: :direct,
      merchant_model: :restaurant_mor,
    )

    refund = PaymentRefund.create!(
      payment_attempt: payment_attempt,
      ordr: ordr,
      restaurant: ordr.restaurant,
      provider: :stripe,
      provider_refund_id: 're_test_123',
      amount_cents: 500,
      currency: 'USD',
      status: :processing,
      provider_response_payload: {},
    )

    payload = {
      'data' => {
        'object' => {
          'id' => 're_test_123',
          'amount' => 500,
          'currency' => 'usd',
        },
      },
    }

    assert_difference('LedgerEvent.count', 1) do
      Payments::Webhooks::StripeIngestor.new.ingest!(
        provider_event_id: 'evt_1',
        provider_event_type: 'refund.updated',
        occurred_at: Time.current,
        payload: payload,
      )
    end

    refund.reload
    assert_equal 'succeeded', refund.status.to_s

    le = LedgerEvent.order(:id).last
    assert_equal 'stripe', le.provider.to_s
    assert_equal 'evt_1', le.provider_event_id
    assert_equal 'refund.updated', le.provider_event_type
    assert_equal 'refund', le.entity_type.to_s
    assert_equal refund.id, le.entity_id
    assert_equal 'refunded', le.event_type.to_s
    assert_equal 500, le.amount_cents
    assert_equal 'USD', le.currency
  end

  test 'is idempotent on provider_event_id' do
    payload = {
      'data' => {
        'object' => {
          'id' => 'cs_test_999',
          'amount_total' => 1000,
          'currency' => 'usd',
          'metadata' => { 'order_id' => ordrs(:one).id.to_s },
        },
      },
    }

    ingestor = Payments::Webhooks::StripeIngestor.new

    assert_difference('LedgerEvent.count', 1) do
      ingestor.ingest!(
        provider_event_id: 'evt_idempotent',
        provider_event_type: 'checkout.session.completed',
        occurred_at: Time.current,
        payload: payload,
      )
    end

    assert_no_difference('LedgerEvent.count') do
      ingestor.ingest!(
        provider_event_id: 'evt_idempotent',
        provider_event_type: 'checkout.session.completed',
        occurred_at: Time.current,
        payload: payload,
      )
    end
  end
end
