# frozen_string_literal: true

module PartnerIntegrations
  # Emits a canonical event to all registered adapters for a restaurant.
  # Adapter dispatch is asynchronous — each adapter is enqueued as a separate
  # PartnerIntegrationDispatchJob so failures are isolated.
  #
  # Usage:
  #   PartnerIntegrations::EventEmitter.emit(
  #     restaurant: restaurant,
  #     event: PartnerIntegrations::CanonicalEvent.new(...)
  #   )
  class EventEmitter
    # Registry mapping adapter_type string → adapter class.
    # Populated at boot time via register_adapter. New adapter types are added here.
    ADAPTER_REGISTRY = {
      'null' => PartnerIntegrations::Adapters::NullAdapter,
    }.freeze

    class << self
      def emit(restaurant:, event:)
        return unless Flipper.enabled?(:partner_integrations, restaurant)

        enabled = Array(restaurant.enabled_integrations).map(&:to_s)
        return if enabled.empty?

        enabled.each do |adapter_type|
          next unless ADAPTER_REGISTRY.key?(adapter_type)

          PartnerIntegrationDispatchJob.perform_later(
            restaurant_id: restaurant.id,
            adapter_type: adapter_type,
            event_payload: event.to_h.deep_stringify_keys,
          )
        end
      end
    end
  end
end
