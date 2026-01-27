module Payments
  class Ledger
    class << self
      def append!(
        provider:,
        provider_event_id:,
        provider_event_type:,
        occurred_at:,
        entity_type:,
        entity_id:,
        event_type:,
        amount_cents: nil,
        currency: nil,
        raw_event_payload: {}
      )
        LedgerEvent.create!(
          provider: provider,
          provider_event_id: provider_event_id.to_s,
          provider_event_type: provider_event_type.to_s,
          entity_type: entity_type,
          entity_id: entity_id,
          event_type: event_type,
          amount_cents: amount_cents,
          currency: currency,
          raw_event_payload: raw_event_payload || {},
          occurred_at: occurred_at,
        )
      rescue ActiveRecord::RecordNotUnique
        nil
      end
    end
  end
end
