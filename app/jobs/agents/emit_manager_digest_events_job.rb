# frozen_string_literal: true

module Agents
  # Agents::EmitManagerDigestEventsJob is enqueued by Heroku Scheduler every
  # Monday at 06:00 UTC. It writes one AgentDomainEvent per eligible restaurant,
  # triggering the ManagerDigestWorkflowJob via the Dispatcher.
  #
  # Eligibility criteria:
  #   - Flipper flag `agent_framework` enabled for the restaurant
  #   - Flipper flag `agent_growth_digest` enabled for the restaurant
  #   - At least MIN_ORDERS_IN_WINDOW orders in the past RECENT_ORDERS_WINDOW_DAYS days
  #
  # This job does NOT run any agent logic — it only emits events.
  class EmitManagerDigestEventsJob < ApplicationJob
    queue_as :agent_low

    RECENT_ORDERS_WINDOW_DAYS = Agents::Workflows::ManagerDigestWorkflow::RECENT_ORDERS_WINDOW_DAYS
    MIN_ORDERS_IN_WINDOW      = Agents::Workflows::ManagerDigestWorkflow::MIN_ORDERS_FOR_DIGEST

    def perform
      emitted = 0
      skipped = 0

      eligible_restaurants.find_each do |restaurant|
        idempotency_key = "manager_digest.scheduled:#{restaurant.id}:#{Date.current.cweek}:#{Date.current.year}"

        AgentDomainEvent.publish!(
          event_type: 'manager_digest.scheduled',
          source: restaurant,
          payload: {
            'restaurant_id' => restaurant.id,
            'triggered_at' => Time.current.iso8601,
          },
          idempotency_key: idempotency_key,
        )

        emitted += 1
      rescue StandardError => e
        Rails.logger.error(
          "[EmitManagerDigestEventsJob] Failed to emit event for restaurant #{restaurant.id}: #{e.message}",
        )
        skipped += 1
      end

      Rails.logger.info("[EmitManagerDigestEventsJob] Emitted #{emitted} events, skipped #{skipped}")
    end

    private

    def eligible_restaurants
      since = RECENT_ORDERS_WINDOW_DAYS.days.ago

      # Fetch all restaurants that have at least MIN_ORDERS_IN_WINDOW recent orders.
      restaurant_ids_with_orders = Ordr
        .where(created_at: since..)
        .group(:restaurant_id)
        .having("COUNT(*) >= #{MIN_ORDERS_IN_WINDOW}")
        .pluck(:restaurant_id)

      return Restaurant.none if restaurant_ids_with_orders.empty?

      # Filter to those with both Flipper flags enabled.
      Restaurant
        .where(id: restaurant_ids_with_orders)
        .select do |r|
          Flipper.enabled?(:agent_framework, r) && Flipper.enabled?(:agent_growth_digest, r)
        end
        .then { |arr| Restaurant.where(id: arr.map(&:id)) }
    end
  end
end
