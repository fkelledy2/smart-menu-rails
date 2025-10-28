class UserSession < ApplicationRecord
  belongs_to :user

  # Validations
  validates :session_id, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[active idle offline] }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :idle, -> { where(status: 'idle') }
  scope :for_resource, ->(type, id) { where(resource_type: type, resource_id: id) }
  scope :recent, -> { where('last_activity_at > ?', 5.minutes.ago) }
  scope :stale, -> { where(last_activity_at: ...5.minutes.ago) }

  # Update activity timestamp
  def touch_activity!
    update(last_activity_at: Time.current, status: 'active')
  end

  # Mark session as idle
  def mark_idle!
    update(status: 'idle')
  end

  # Mark session as offline
  def mark_offline!
    update(status: 'offline')
  end

  # Check if session is stale
  def stale?
    last_activity_at.nil? || last_activity_at < 5.minutes.ago
  end
end
