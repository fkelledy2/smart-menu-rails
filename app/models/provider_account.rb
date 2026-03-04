class ProviderAccount < ApplicationRecord
  belongs_to :restaurant

  encrypts :access_token
  encrypts :refresh_token

  enum :provider, {
    stripe: 0,
    square: 1,
  }

  enum :status, {
    created: 0,
    onboarding: 10,
    enabled: 20,
    restricted: 30,
    disabled: 40,
  }

  validates :provider, presence: true
  validates :provider_account_id, presence: true, if: :stripe?
  validates :status, presence: true
  validates :environment, inclusion: { in: %w[production sandbox] }

  def token_expired?
    token_expires_at.present? && token_expires_at < Time.current
  end

  def token_expiring_soon?(within: 7.days)
    token_expires_at.present? && token_expires_at < within.from_now
  end
end
