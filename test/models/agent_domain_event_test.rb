# frozen_string_literal: true

require 'test_helper'

class AgentDomainEventTest < ActiveSupport::TestCase
  # --- Validations ---

  test 'valid with required attributes' do
    event = AgentDomainEvent.new(
      event_type: 'order.completed',
      idempotency_key: "key-#{SecureRandom.hex(8)}",
      payload: { 'restaurant_id' => 1 },
    )
    assert event.valid?
  end

  test 'invalid without event_type' do
    event = AgentDomainEvent.new(
      idempotency_key: "key-#{SecureRandom.hex(8)}",
    )
    assert_not event.valid?
  end

  test 'invalid without idempotency_key' do
    event = AgentDomainEvent.new(event_type: 'order.completed')
    assert_not event.valid?
  end

  test 'enforces uniqueness of idempotency_key' do
    AgentDomainEvent.create!(
      event_type: 'order.completed',
      idempotency_key: 'unique-key-abc',
      payload: {},
    )
    duplicate = AgentDomainEvent.new(
      event_type: 'menu.updated',
      idempotency_key: 'unique-key-abc',
      payload: {},
    )
    assert_not duplicate.valid?
  end

  # --- Scopes ---

  test 'unprocessed scope returns events without processed_at' do
    AgentDomainEvent.unprocessed.each { |e| assert_nil e.processed_at }
  end

  test 'processed scope returns events with processed_at' do
    AgentDomainEvent.processed.each { |e| assert_not_nil e.processed_at }
  end

  # --- Instance methods ---

  test 'processed? returns false when processed_at is nil' do
    event = agent_domain_events(:unprocessed_event)
    assert_not event.processed?
  end

  test 'processed? returns true when processed_at is set' do
    event = agent_domain_events(:processed_event)
    assert event.processed?
  end

  test 'mark_processed! sets processed_at' do
    event = agent_domain_events(:unprocessed_event)
    event.mark_processed!
    assert_not_nil event.reload.processed_at
  end

  # --- publish! ---

  test 'publish! creates a new domain event' do
    key = "publish-test-#{SecureRandom.hex(8)}"
    assert_difference 'AgentDomainEvent.count', 1 do
      AgentDomainEvent.publish!(
        event_type: 'test.event',
        payload: { 'data' => 'value' },
        idempotency_key: key,
      )
    end
  end

  test 'publish! is idempotent with same key' do
    key = "idempotent-#{SecureRandom.hex(8)}"
    AgentDomainEvent.publish!(event_type: 'test.event', idempotency_key: key)
    assert_no_difference 'AgentDomainEvent.count' do
      AgentDomainEvent.publish!(event_type: 'test.event', idempotency_key: key)
    end
  end
end
