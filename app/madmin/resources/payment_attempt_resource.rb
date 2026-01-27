class PaymentAttemptResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :provider
  attribute :provider_payment_id
  attribute :amount_cents
  attribute :currency
  attribute :status
  attribute :charge_pattern
  attribute :merchant_model
  attribute :platform_fee_cents
  attribute :provider_fee_cents
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :ordr
  attribute :restaurant
end
