# frozen_string_literal: true

module Agents
  # Agents::KitchenHeartbeatJob runs every 60 seconds via Sidekiq cron.
  # It emits a `kitchen.queue_check` domain event for each restaurant that:
  #   (a) has the agent_service_operations Flipper flag enabled, AND
  #   (b) has at least one active (non-terminal) order
  #
  # Idle restaurants are skipped to avoid unnecessary workflow runs.
  # Queue: agent_realtime
  class KitchenHeartbeatJob < ApplicationJob
    queue_as :agent_realtime

    ACTIVE_ORDER_STATUSES = %w[opened ordered preparing ready delivered billrequested].freeze

    def perform
      eligible_restaurant_ids.each do |restaurant_id|
        restaurant = Restaurant.find_by(id: restaurant_id)
        next unless restaurant
        next unless Flipper.enabled?(:agent_framework, restaurant)
        next unless Flipper.enabled?(:agent_service_operations, restaurant)

        AgentDomainEvent.publish!(
          event_type: 'kitchen.queue_check',
          source: restaurant,
          payload: {
            'restaurant_id' => restaurant_id,
            'triggered_at' => Time.current.iso8601,
          },
          idempotency_key: "kitchen.queue_check:#{restaurant_id}:#{Time.current.strftime('%Y%m%d%H%M')}",
        )

        Rails.logger.info("[KitchenHeartbeatJob] Emitted kitchen.queue_check for restaurant #{restaurant_id}")
      end
    end

    private

    def eligible_restaurant_ids
      Ordr
        .where(status: ACTIVE_ORDER_STATUSES)
        .where(updated_at: 24.hours.ago..)
        .distinct
        .pluck(:restaurant_id)
    end
  end
end
