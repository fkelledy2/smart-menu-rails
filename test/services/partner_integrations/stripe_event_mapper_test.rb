# frozen_string_literal: true

require 'test_helper'

class PartnerIntegrations::StripeEventMapperTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
  end

  def payment_intent_payload(order_id: '42', pi_id: 'pi_test_123', amount: 2500, currency: 'usd')
    {
      'data' => {
        'object' => {
          'id' => pi_id,
          'amount_received' => amount,
          'currency' => currency,
          'metadata' => { 'order_id' => order_id },
        },
      },
    }
  end

  test 'maps payment_intent.succeeded to canonical order.payment.succeeded event' do
    event = PartnerIntegrations::StripeEventMapper.map(
      provider_event_type: 'payment_intent.succeeded',
      payload: payment_intent_payload,
      restaurant: @restaurant,
    )

    assert_not_nil event
    assert_equal 'order.payment.succeeded', event.event_type
    assert_equal @restaurant.id, event.restaurant_id
    assert_equal 'stripe', event.payload[:provider]
    assert_equal 'pi_test_123', event.payload[:provider_payment_id]
    assert_equal '42', event.payload[:order_id]
    assert_equal 2500, event.payload[:amount_cents]
    assert_equal 'USD', event.payload[:currency]
  end

  test 'returns nil for unmapped event types' do
    result = PartnerIntegrations::StripeEventMapper.map(
      provider_event_type: 'customer.created',
      payload: {},
      restaurant: @restaurant,
    )
    assert_nil result
  end

  test 'returns nil for charge.refunded (not mapped)' do
    result = PartnerIntegrations::StripeEventMapper.map(
      provider_event_type: 'charge.refunded',
      payload: {},
      restaurant: @restaurant,
    )
    assert_nil result
  end

  test 'idempotency_key encodes provider and payment intent id' do
    event = PartnerIntegrations::StripeEventMapper.map(
      provider_event_type: 'payment_intent.succeeded',
      payload: payment_intent_payload(pi_id: 'pi_abc123'),
      restaurant: @restaurant,
    )
    assert_equal 'stripe:payment_intent:pi_abc123', event.idempotency_key
  end

  test 'handles missing metadata gracefully' do
    payload = { 'data' => { 'object' => { 'id' => 'pi_x', 'amount_received' => 100, 'currency' => 'eur' } } }
    event = PartnerIntegrations::StripeEventMapper.map(
      provider_event_type: 'payment_intent.succeeded',
      payload: payload,
      restaurant: @restaurant,
    )
    assert_not_nil event
    assert_nil event.payload[:order_id]
  end
end
