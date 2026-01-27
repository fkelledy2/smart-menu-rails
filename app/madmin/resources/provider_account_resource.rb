class ProviderAccountResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :provider
  attribute :provider_account_id
  attribute :account_type
  attribute :country
  attribute :currency
  attribute :status
  attribute :capabilities
  attribute :payouts_enabled
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :restaurant
end
