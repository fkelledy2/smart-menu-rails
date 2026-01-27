module Payments
  class NormalizedEvent
    attr_reader :provider,
                :provider_event_id,
                :provider_event_type,
                :occurred_at,
                :entity_type,
                :entity_id,
                :event_type,
                :amount_cents,
                :currency,
                :metadata

    def initialize(
      provider:,
      provider_event_id:,
      provider_event_type:,
      occurred_at:,
      entity_type:,
      entity_id:,
      event_type:,
      amount_cents: nil,
      currency: nil,
      metadata: {}
    )
      @provider = provider.to_sym
      @provider_event_id = provider_event_id.to_s
      @provider_event_type = provider_event_type.to_s
      @occurred_at = occurred_at
      @entity_type = entity_type.to_sym
      @entity_id = entity_id
      @event_type = event_type.to_sym
      @amount_cents = amount_cents
      @currency = currency
      @metadata = metadata || {}
    end

    def ledger_attributes
      {
        provider: provider,
        provider_event_id: provider_event_id,
        provider_event_type: provider_event_type,
        occurred_at: occurred_at,
        entity_type: entity_type,
        entity_id: entity_id,
        event_type: event_type,
        amount_cents: amount_cents,
        currency: currency,
      }
    end
  end
end
