class PaymentRefundResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :provider
  attribute :provider_refund_id
  attribute :amount_cents
  attribute :currency
  attribute :status
  attribute :provider_response_payload
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :payment_attempt
  attribute :ordr
  attribute :restaurant
end
