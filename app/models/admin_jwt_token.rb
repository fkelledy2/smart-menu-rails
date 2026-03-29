# frozen_string_literal: true

class AdminJwtToken < ApplicationRecord
  VALID_SCOPES = %w[
    menu:read
    menu:write
    orders:read
    orders:write
    analytics:read
    settings:read
    workforce:read
    crm:read
  ].freeze

  EXPIRY_OPTIONS = {
    '30_days' => 30.days,
    '60_days' => 60.days,
    '90_days' => 90.days,
  }.freeze

  belongs_to :admin_user, class_name: 'User'
  belongs_to :restaurant
  has_many :usage_logs, class_name: 'JwtTokenUsageLog', foreign_key: :jwt_token_id,
                        dependent: :destroy, inverse_of: :jwt_token

  validates :name, presence: true, length: { maximum: 255 }
  validates :token_hash, presence: true, uniqueness: true
  validates :scopes, presence: true
  validates :expires_at, presence: true
  validates :rate_limit_per_minute, numericality: { greater_than: 0, less_than_or_equal_to: 1000 }
  validates :rate_limit_per_hour, numericality: { greater_than: 0, less_than_or_equal_to: 10_000 }
  validate  :scopes_are_valid
  validate  :expires_at_is_future, on: :create

  scope :active,   -> { where(revoked_at: nil).where('expires_at > ?', Time.current) }
  scope :revoked,  -> { where.not(revoked_at: nil) }
  scope :expired,  -> { where(revoked_at: nil).where(expires_at: ..Time.current) }
  scope :expiring_soon, lambda { |days = 7|
    where(revoked_at: nil).where(expires_at: Time.current..days.days.from_now)
  }
  scope :for_restaurant, ->(restaurant_id) { where(restaurant_id: restaurant_id) }

  def active?
    revoked_at.nil? && expires_at > Time.current
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    !revoked? && expires_at <= Time.current
  end

  def status
    return :revoked if revoked?
    return :expired if expired?

    :active
  end

  def status_badge_class
    { active: 'bg-success', revoked: 'bg-danger', expired: 'bg-secondary' }[status]
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def record_usage!(endpoint:, http_method:, ip_address:, response_status:)
    usage_logs.create!(
      endpoint: endpoint,
      http_method: http_method,
      ip_address: ip_address,
      response_status: response_status,
    )
    # Atomic SQL increment to avoid lost updates under concurrent requests.
    self.class.where(id: id).update_all('last_used_at = NOW(), usage_count = usage_count + 1')
  end

  private

  def scopes_are_valid
    return if scopes.blank?

    invalid = Array(scopes) - VALID_SCOPES
    errors.add(:scopes, "contains invalid values: #{invalid.join(', ')}") if invalid.any?
  end

  def expires_at_is_future
    return if expires_at.blank?

    errors.add(:expires_at, 'must be in the future') unless expires_at > Time.current
  end
end
