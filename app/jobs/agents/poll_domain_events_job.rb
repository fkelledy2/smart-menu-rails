# frozen_string_literal: true

module Agents
  # Polls agent_domain_events for unprocessed records and dispatches them.
  # Uses polling (not LISTEN/NOTIFY) for PgBouncer compatibility.
  # Runs every 30 seconds via Sidekiq cron.
  class PollDomainEventsJob < ApplicationJob
    queue_as :agent_default

    BATCH_SIZE = 50

    def perform
      AgentDomainEvent
        .unprocessed
        .order(created_at: :asc)
        .limit(BATCH_SIZE)
        .find_each do |event|
          result = Agents::Dispatcher.call(event)
          event.mark_processed!

          Rails.logger.info("[Agents::PollDomainEventsJob] Event #{event.id} (#{event.event_type}): #{result}")
        rescue StandardError => e
          Rails.logger.error("[Agents::PollDomainEventsJob] Failed to dispatch event #{event.id}: #{e.message}")
        end
    end
  end
end
