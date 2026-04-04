# frozen_string_literal: true

module Agents
  # Agents::EmitMenuOptimizationEventsJob is enqueued by Heroku Scheduler every
  # night at 02:00 UTC. It writes one AgentDomainEvent per eligible restaurant,
  # triggering the MenuOptimizationWorkflowJob via the Dispatcher.
  #
  # Eligibility criteria:
  #   - Flipper flag `agent_framework` enabled for the restaurant
  #   - Flipper flag `agent_menu_optimization` enabled for the restaurant
  #   - At least 14 days of order history exists for the restaurant
  #
  # This job does NOT run any agent logic — it only emits events.
  class EmitMenuOptimizationEventsJob < ApplicationJob
    queue_as :agent_low

    MIN_ORDER_HISTORY_DAYS = Agents::Workflows::MenuOptimizationWorkflow::MIN_ORDERS_WINDOW

    def perform
      emitted = 0
      skipped = 0

      eligible_restaurants.find_each do |restaurant|
        # Idempotency: one event per restaurant per ISO week
        idempotency_key = "menu_optimization.scheduled:#{restaurant.id}:#{Date.current.cweek}:#{Date.current.year}"

        AgentDomainEvent.publish!(
          event_type: 'menu_optimization.scheduled',
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
          "[EmitMenuOptimizationEventsJob] Failed to emit event for restaurant #{restaurant.id}: #{e.message}",
        )
        skipped += 1
      end

      Rails.logger.info("[EmitMenuOptimizationEventsJob] Emitted #{emitted} events, skipped #{skipped}")
    end

    private

    def eligible_restaurants
      cutoff = MIN_ORDER_HISTORY_DAYS.days.ago

      # Restaurants that have at least one order older than MIN_ORDER_HISTORY_DAYS days.
      restaurant_ids_with_history = Ordr
        .where(created_at: ..cutoff)
        .distinct
        .pluck(:restaurant_id)

      return Restaurant.none if restaurant_ids_with_history.empty?

      Restaurant
        .where(id: restaurant_ids_with_history)
        .select do |r|
          Flipper.enabled?(:agent_framework, r) && Flipper.enabled?(:agent_menu_optimization, r)
        end
        .then { |arr| Restaurant.where(id: arr.map(&:id)) }
    end
  end
end
