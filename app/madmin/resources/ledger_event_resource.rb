class LedgerEventResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :provider
  attribute :provider_event_id
  attribute :provider_event_type
  attribute :entity_type
  attribute :entity_id
  attribute :event_type
  attribute :amount_cents
  attribute :currency
  attribute :raw_event_payload
  attribute :occurred_at
  attribute :created_at, form: false
  attribute :updated_at, form: false
end
