class PaymentProfileResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :merchant_model
  attribute :primary_provider
  attribute :fallback_providers
  attribute :default_country
  attribute :default_currency
  attribute :fee_model
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :restaurant
end
