# frozen_string_literal: true

require 'test_helper'

class Crm::ProcessCalendlyWebhookJobTest < ActiveSupport::TestCase
  # Crm::ProcessCalendlyWebhookJob delegates entirely to Crm::CalendlyEventHandler.call.
  # Tests verify delegation and error propagation.

  test 'perform delegates to CalendlyEventHandler.call with payload' do
    payload = { 'event' => 'invitee.created', 'payload' => { 'email' => 'test@test.com' } }
    handler_called = false
    received_payload = nil

    Crm::CalendlyEventHandler.stub(:call, ->(payload:) { handler_called = true; received_payload = payload; nil }) do
      Crm::ProcessCalendlyWebhookJob.new.perform(payload)
    end

    assert handler_called, 'CalendlyEventHandler.call should have been invoked'
    assert_equal payload, received_payload
  end

  test 'perform passes payload hash through unchanged' do
    payload = {
      'event' => 'invitee.canceled',
      'payload' => { 'email' => 'cancel@test.com', 'name' => 'Test User' },
    }

    Crm::CalendlyEventHandler.stub(:call, ->(payload:) { nil }) do
      # No exception should be raised
      assert_nothing_raised { Crm::ProcessCalendlyWebhookJob.new.perform(payload) }
    end
  end

  test 'job has a configured queue' do
    queue = Crm::ProcessCalendlyWebhookJob.sidekiq_options_hash['queue']
    assert queue.present?, 'queue should be configured'
  end
end
