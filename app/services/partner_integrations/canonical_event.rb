# frozen_string_literal: true

module PartnerIntegrations
  # Immutable value object representing a canonical partner event.
  # Adapters receive this object via their `call(event:)` interface and
  # cannot mutate it (all attributes are frozen on build).
  class CanonicalEvent
    VALID_EVENT_TYPES = %w[
      order.created
      order.status_changed
      order.payment.succeeded
      table.occupied
      table.freed
    ].freeze

    attr_reader :event_type,
                :restaurant_id,
                :occurred_at,
                :payload,
                :idempotency_key

    def initialize(event_type:, restaurant_id:, occurred_at:, payload:, idempotency_key:)
      raise ArgumentError, "Unknown event_type: #{event_type}" unless VALID_EVENT_TYPES.include?(event_type.to_s)
      raise ArgumentError, 'restaurant_id is required' if restaurant_id.blank?
      raise ArgumentError, 'occurred_at is required' if occurred_at.nil?

      @event_type      = event_type.to_s.freeze
      @restaurant_id   = restaurant_id
      @occurred_at     = occurred_at
      @payload         = payload.to_h.freeze
      @idempotency_key = idempotency_key.to_s.freeze
      freeze
    end

    def to_h
      {
        event_type: @event_type,
        restaurant_id: @restaurant_id,
        occurred_at: @occurred_at.iso8601,
        payload: @payload,
        idempotency_key: @idempotency_key,
      }
    end

    def to_json(*_args)
      to_h.to_json
    end
  end
end
