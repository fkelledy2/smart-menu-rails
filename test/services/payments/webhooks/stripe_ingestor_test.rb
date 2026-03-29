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

  test 'emits canonical partner event on payment_intent.succeeded when integrations enabled' do
    ordr = ordrs(:one)
    restaurant = ordr.restaurant
    restaurant.update!(enabled_integrations: ['null'])
    Flipper.enable(:partner_integrations, restaurant)

    pi_id = 'pi_partner_test_456'
    payload = {
      'data' => {
        'object' => {
          'id' => pi_id,
          'amount_received' => 2000,
          'currency' => 'eur',
          'metadata' => { 'order_id' => ordr.id.to_s },
        },
      },
    }

    emit_called = false
    emit_args = nil
    fake_emit = lambda do |restaurant:, event:|
      emit_called = true
      emit_args   = { restaurant: restaurant, event: event }
    end

    PartnerIntegrations::EventEmitter.stub(:emit, fake_emit) do
      Payments::Webhooks::StripeIngestor.new.ingest!(
        provider_event_id: 'evt_partner_pi',
        provider_event_type: 'payment_intent.succeeded',
        occurred_at: Time.current,
        payload: payload,
      )
    end

    assert emit_called, 'Expected EventEmitter.emit to be called'
    assert_equal restaurant.id, emit_args[:restaurant].id
    assert_equal 'order.payment.succeeded', emit_args[:event].event_type
  ensure
    Flipper.disable(:partner_integrations)
    restaurant.update!(enabled_integrations: [])
  end

  test 'does not raise when partner event emission fails' do
    ordr = ordrs(:one)
    restaurant = ordr.restaurant
    restaurant.update!(enabled_integrations: ['null'])
    Flipper.enable(:partner_integrations, restaurant)

    payload = {
      'data' => {
        'object' => {
          'id' => 'pi_boom',
          'amount_received' => 500,
          'currency' => 'usd',
          'metadata' => { 'order_id' => ordr.id.to_s },
        },
      },
    }

    bomb = ->(**_) { raise 'partner system down' }

    assert_nothing_raised do
      PartnerIntegrations::EventEmitter.stub(:emit, bomb) do
        Payments::Webhooks::StripeIngestor.new.ingest!(
          provider_event_id: 'evt_boom_pi',
          provider_event_type: 'payment_intent.succeeded',
          occurred_at: Time.current,
          payload: payload,
        )
      end
    end
  ensure
    Flipper.disable(:partner_integrations)
    restaurant.update!(enabled_integrations: [])
  end
end
