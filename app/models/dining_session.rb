class DiningSession < ApplicationRecord
  SESSION_TTL = 90.minutes
  INACTIVITY_TIMEOUT = 30.minutes

  belongs_to :smartmenu
  belongs_to :tablesetting
  belongs_to :restaurant

  validates :session_token, presence: true, uniqueness: true, length: { is: 64 }
  validates :expires_at, presence: true
  validates :active, inclusion: { in: [true, false] }

  before_validation :set_expiry, on: :create

  scope :valid, lambda {
    where(active: true)
      .where('expires_at > ?', Time.current)
      .where('last_activity_at IS NULL OR last_activity_at > ?', INACTIVITY_TIMEOUT.ago)
  }

  scope :expired, lambda {
    where(active: true)
      .where(
        'expires_at <= ? OR (last_activity_at IS NOT NULL AND last_activity_at <= ?)',
        Time.current,
        INACTIVITY_TIMEOUT.ago,
      )
  }

  def expired?
    return true unless active?
    return true if expires_at <= Time.current
    return true if last_activity_at.present? && last_activity_at <= INACTIVITY_TIMEOUT.ago

    false
  end

  def touch_activity!
    update_column(:last_activity_at, Time.current)
  end

  def invalidate!
    update_column(:active, false)
  end

  private

  def set_expiry
    self.expires_at ||= SESSION_TTL.from_now
    self.last_activity_at ||= Time.current
  end
end
