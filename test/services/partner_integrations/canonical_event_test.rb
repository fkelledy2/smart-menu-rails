# frozen_string_literal: true

require 'test_helper'

class PartnerIntegrations::CanonicalEventTest < ActiveSupport::TestCase
  def valid_attrs
    {
      event_type: 'order.payment.succeeded',
      restaurant_id: 1,
      occurred_at: Time.zone.now,
      payload: { provider: 'stripe' },
      idempotency_key: 'test-key-123',
    }
  end

  test 'builds successfully with valid attributes' do
    event = PartnerIntegrations::CanonicalEvent.new(**valid_attrs)
    assert_equal 'order.payment.succeeded', event.event_type
    assert_equal 1, event.restaurant_id
    assert_equal 'test-key-123', event.idempotency_key
  end

  test 'raises on unknown event_type' do
    assert_raises(ArgumentError) do
      PartnerIntegrations::CanonicalEvent.new(**valid_attrs.merge(event_type: 'unknown.event'))
    end
  end

  test 'raises on blank restaurant_id' do
    assert_raises(ArgumentError) do
      PartnerIntegrations::CanonicalEvent.new(**valid_attrs.merge(restaurant_id: nil))
    end
  end

  test 'raises on nil occurred_at' do
    assert_raises(ArgumentError) do
      PartnerIntegrations::CanonicalEvent.new(**valid_attrs.merge(occurred_at: nil))
    end
  end

  test 'is frozen after construction' do
    event = PartnerIntegrations::CanonicalEvent.new(**valid_attrs)
    assert event.frozen?
  end

  test 'payload is frozen' do
    event = PartnerIntegrations::CanonicalEvent.new(**valid_attrs)
    assert event.payload.frozen?
  end

  test 'to_h returns expected keys' do
    event = PartnerIntegrations::CanonicalEvent.new(**valid_attrs)
    h = event.to_h
    assert_includes h.keys, :event_type
    assert_includes h.keys, :restaurant_id
    assert_includes h.keys, :occurred_at
    assert_includes h.keys, :payload
    assert_includes h.keys, :idempotency_key
  end

  test 'to_h occurred_at is ISO8601 string' do
    t = Time.zone.parse('2026-03-29T12:00:00Z')
    event = PartnerIntegrations::CanonicalEvent.new(**valid_attrs.merge(occurred_at: t))
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, event.to_h[:occurred_at])
  end

  test 'supports all valid event types' do
    PartnerIntegrations::CanonicalEvent::VALID_EVENT_TYPES.each do |et|
      event = PartnerIntegrations::CanonicalEvent.new(**valid_attrs.merge(event_type: et))
      assert_equal et, event.event_type
    end
  end
end
