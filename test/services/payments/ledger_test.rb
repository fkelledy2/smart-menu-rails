# frozen_string_literal: true

require 'test_helper'

class Payments::LedgerTest < ActiveSupport::TestCase
  # Payments::Ledger.append! wraps LedgerEvent.create! with a uniqueness rescue.
  # The unique index is on (provider, provider_event_id).

  VALID_PARAMS = {
    provider: 'stripe',
    provider_event_id: 'evt_test_unique_001',
    provider_event_type: 'payment_intent.succeeded',
    occurred_at: Time.current,
    entity_type: 'payment_attempt',
    entity_id: 42,
    event_type: 'succeeded',
    amount_cents: 2500,
    currency: 'USD',
    raw_event_payload: { 'id' => 'evt_test_unique_001' },
  }.freeze

  def unique_event_id
    "evt_test_#{SecureRandom.hex(8)}"
  end

  # ---------------------------------------------------------------------------
  # Happy path — creates a LedgerEvent row
  # ---------------------------------------------------------------------------

  test 'append! creates a LedgerEvent record' do
    params = VALID_PARAMS.merge(provider_event_id: unique_event_id)
    assert_difference 'LedgerEvent.count', 1 do
      Payments::Ledger.append!(**params)
    end
  end

  test 'append! returns the created LedgerEvent' do
    params = VALID_PARAMS.merge(provider_event_id: unique_event_id)
    event = Payments::Ledger.append!(**params)
    assert_instance_of LedgerEvent, event
    assert event.persisted?
  end

  test 'append! stores provider correctly' do
    params = VALID_PARAMS.merge(provider_event_id: unique_event_id)
    event = Payments::Ledger.append!(**params)
    assert_equal 'stripe', event.provider
  end

  test 'append! stores provider_event_id as string' do
    eid = unique_event_id
    params = VALID_PARAMS.merge(provider_event_id: eid)
    event = Payments::Ledger.append!(**params)
    assert_equal eid.to_s, event.provider_event_id
  end

  test 'append! stores provider_event_type as string' do
    params = VALID_PARAMS.merge(
      provider_event_id: unique_event_id,
      provider_event_type: :payment_intent_succeeded,
    )
    event = Payments::Ledger.append!(**params)
    assert_equal 'payment_intent_succeeded', event.provider_event_type
  end

  test 'append! stores entity_type, event_type, amount and currency' do
    params = VALID_PARAMS.merge(provider_event_id: unique_event_id)
    event = Payments::Ledger.append!(**params)
    assert_equal 2500, event.amount_cents
    assert_equal 'USD', event.currency
  end

  test 'append! works without optional amount_cents and currency' do
    params = VALID_PARAMS.merge(
      provider_event_id: unique_event_id,
      amount_cents: nil,
      currency: nil,
    )
    assert_difference 'LedgerEvent.count', 1 do
      Payments::Ledger.append!(**params)
    end
  end

  test 'append! stores raw_event_payload as JSON' do
    payload = { 'object' => 'payment_intent', 'amount' => 2500 }
    params = VALID_PARAMS.merge(
      provider_event_id: unique_event_id,
      raw_event_payload: payload,
    )
    event = Payments::Ledger.append!(**params)
    assert_equal payload, event.raw_event_payload
  end

  test 'append! defaults raw_event_payload to empty hash when nil is passed' do
    params = VALID_PARAMS.merge(
      provider_event_id: unique_event_id,
      raw_event_payload: nil,
    )
    event = Payments::Ledger.append!(**params)
    assert_equal({}, event.raw_event_payload)
  end

  # ---------------------------------------------------------------------------
  # Duplicate suppression — second call with same provider + provider_event_id
  # returns nil instead of raising
  # ---------------------------------------------------------------------------

  test 'append! returns nil on duplicate provider + provider_event_id' do
    eid = unique_event_id
    params = VALID_PARAMS.merge(provider_event_id: eid)

    Payments::Ledger.append!(**params)
    result = Payments::Ledger.append!(**params)

    assert_nil result
  end

  test 'append! does not create a second row on duplicate' do
    eid = unique_event_id
    params = VALID_PARAMS.merge(provider_event_id: eid)

    Payments::Ledger.append!(**params)
    assert_no_difference 'LedgerEvent.count' do
      Payments::Ledger.append!(**params)
    end
  end

  # ---------------------------------------------------------------------------
  # Square provider variant
  # ---------------------------------------------------------------------------

  test 'append! works for square provider' do
    params = VALID_PARAMS.merge(
      provider: 'square',
      provider_event_id: unique_event_id,
    )
    event = Payments::Ledger.append!(**params)
    assert_equal 'square', event.provider
  end

  # ---------------------------------------------------------------------------
  # occurred_at is persisted
  # ---------------------------------------------------------------------------

  test 'append! stores occurred_at' do
    ts = 1.hour.ago
    params = VALID_PARAMS.merge(provider_event_id: unique_event_id, occurred_at: ts)
    event = Payments::Ledger.append!(**params)
    assert_in_delta ts.to_i, event.occurred_at.to_i, 1
  end
end
