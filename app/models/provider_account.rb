class ProviderAccount < ApplicationRecord
  belongs_to :restaurant

  enum :provider, {
    stripe: 0,
  }

  enum :status, {
    created: 0,
    onboarding: 10,
    enabled: 20,
    restricted: 30,
    disabled: 40,
  }

  validates :restaurant, presence: true
  validates :provider, presence: true
  validates :provider_account_id, presence: true
  validates :status, presence: true
end
