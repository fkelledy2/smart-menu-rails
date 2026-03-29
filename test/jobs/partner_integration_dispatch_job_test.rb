# frozen_string_literal: true

require 'test_helper'

class PartnerIntegrationDispatchJobTest < ActiveJob::TestCase
  def setup
    @restaurant = restaurants(:one)
    @event_payload = {
      'event_type'      => 'order.payment.succeeded',
      'restaurant_id'   => @restaurant.id,
      'occurred_at'     => Time.zone.now.iso8601,
      'idempotency_key' => 'stripe:payment_intent:pi_test_123',
      'payload'         => { 'provider' => 'stripe' },
    }
  end

  test 'dispatches successfully to a registered adapter (null adapter no-ops cleanly)' do
    # The NullAdapter logs and returns true — just verify no error is raised
    assert_nothing_raised do
      PartnerIntegrationDispatchJob.new.perform(
        restaurant_id: @restaurant.id,
        adapter_type: 'null',
        event_payload: @event_payload,
      )
    end
  end

  test 'no-ops silently when restaurant not found' do
    assert_nothing_raised do
      PartnerIntegrationDispatchJob.new.perform(
        restaurant_id: 999_999,
        adapter_type: 'null',
        event_payload: @event_payload,
      )
    end
  end

  test 'no-ops when adapter_type is not registered' do
    assert_nothing_raised do
      PartnerIntegrationDispatchJob.new.perform(
        restaurant_id: @restaurant.id,
        adapter_type: 'unknown_adapter',
        event_payload: @event_payload,
      )
    end
  end

  test 'no-ops when event_payload cannot be built into a CanonicalEvent' do
    bad_payload = @event_payload.merge('event_type' => 'bad.event.type')
    assert_nothing_raised do
      PartnerIntegrationDispatchJob.new.perform(
        restaurant_id: @restaurant.id,
        adapter_type: 'null',
        event_payload: bad_payload,
      )
    end
  end

  test 'records dead-letter log when record_dead_letter is called directly' do
    job = PartnerIntegrationDispatchJob.new
    job.instance_variable_set(:@restaurant_id, @restaurant.id)
    job.instance_variable_set(:@adapter_type, 'null')
    job.instance_variable_set(:@event_payload, @event_payload)

    assert_difference -> { PartnerIntegrationErrorLog.count }, 1 do
      job.send(:record_dead_letter, StandardError.new('adapter exploded'))
    end

    log = PartnerIntegrationErrorLog.order(:created_at).last
    assert_equal @restaurant.id, log.restaurant_id
    assert_equal 'null', log.adapter_type
    assert_equal 'order.payment.succeeded', log.event_type
    assert_match 'adapter exploded', log.error_message
    assert_equal PartnerIntegrationDispatchJob::MAX_ATTEMPTS, log.attempt_number
  end
end
