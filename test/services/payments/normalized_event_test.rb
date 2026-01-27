require 'test_helper'

class Payments::NormalizedEventTest < ActiveSupport::TestCase
  test 'ledger_attributes includes required keys' do
    evt = Payments::NormalizedEvent.new(
      provider: :stripe,
      provider_event_id: 'evt_123',
      provider_event_type: 'payment_intent.succeeded',
      occurred_at: Time.current,
      entity_type: :payment_attempt,
      entity_id: 1,
      event_type: :succeeded,
      amount_cents: 1234,
      currency: 'EUR'
    )

    attrs = evt.ledger_attributes
    assert_equal :stripe, attrs[:provider]
    assert_equal 'evt_123', attrs[:provider_event_id]
    assert_equal 'payment_intent.succeeded', attrs[:provider_event_type]
    assert_equal :payment_attempt, attrs[:entity_type]
    assert_equal 1, attrs[:entity_id]
    assert_equal :succeeded, attrs[:event_type]
    assert_equal 1234, attrs[:amount_cents]
    assert_equal 'EUR', attrs[:currency]
  end
end
