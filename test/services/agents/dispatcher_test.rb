# frozen_string_literal: true

require 'test_helper'

class Agents::DispatcherTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    # Register a test workflow type
    Agents::Dispatcher.registry['test.event'] = 'test_workflow'
  end

  def teardown
    Agents::Dispatcher.registry.delete('test.event')
  end

  def make_event(event_type: 'test.event', restaurant_id: nil)
    rid = restaurant_id || @restaurant.id
    AgentDomainEvent.create!(
      event_type: event_type,
      idempotency_key: "dispatcher-test-#{SecureRandom.hex(8)}",
      payload: { 'restaurant_id' => rid },
    )
  end

  test 'returns :skipped_no_workflow for unregistered event_type' do
    event = make_event(event_type: 'unknown.event')
    result = Agents::Dispatcher.call(event)
    assert_equal :skipped_no_workflow, result
  end

  test 'returns :skipped_no_workflow when restaurant_id not in payload' do
    event = AgentDomainEvent.create!(
      event_type: 'test.event',
      idempotency_key: "no-restaurant-#{SecureRandom.hex(8)}",
      payload: {},
    )
    result = Agents::Dispatcher.call(event)
    assert_equal :skipped_no_workflow, result
  end

  test 'returns :skipped_flag when agent_framework flag is disabled' do
    Flipper.disable(:agent_framework, @restaurant)
    event = make_event
    result = Agents::Dispatcher.call(event)
    assert_equal :skipped_flag, result
  ensure
    Flipper.disable(:agent_framework, @restaurant)
  end

  test 'enqueues a workflow run when flag is enabled' do
    Flipper.enable(:agent_framework, @restaurant)
    event = make_event

    assert_difference 'AgentWorkflowRun.count', 1 do
      result = Agents::Dispatcher.call(event)
      assert_equal :enqueued, result
    end
  ensure
    Flipper.disable(:agent_framework, @restaurant)
  end

  test 'returns :skipped_duplicate for already active run with same type' do
    Flipper.enable(:agent_framework, @restaurant)

    # Create a pre-existing active run
    AgentWorkflowRun.create!(
      restaurant: @restaurant,
      workflow_type: 'test_workflow',
      trigger_event: 'test.event',
      status: 'running',
      context_snapshot: {},
    )

    event = make_event
    result = Agents::Dispatcher.call(event)
    assert_equal :skipped_duplicate, result
  ensure
    Flipper.disable(:agent_framework, @restaurant)
  end
end
