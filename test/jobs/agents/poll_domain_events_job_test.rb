# frozen_string_literal: true

require 'test_helper'

class Agents::PollDomainEventsJobTest < ActiveSupport::TestCase
  test 'marks unprocessed events as processed' do
    event = agent_domain_events(:unprocessed_event)
    assert_not event.processed?

    Agents::PollDomainEventsJob.new.perform

    assert event.reload.processed?
  end

  test 'does not re-process already processed events' do
    event = agent_domain_events(:processed_event)
    original_processed_at = event.processed_at

    Agents::PollDomainEventsJob.new.perform

    assert_equal original_processed_at.to_i, event.reload.processed_at.to_i
  end
end
