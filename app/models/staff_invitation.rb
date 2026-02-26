class StaffInvitation < ApplicationRecord
  belongs_to :restaurant
  belongs_to :invited_by, class_name: 'User'

  enum :role, { staff: 0, manager: 1, admin: 2 }
  enum :status, { pending: 0, accepted: 1, expired: 2, revoked: 3 }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :role, presence: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create
  before_validation :set_expiry, on: :create

  scope :active, -> { where(status: :pending).where('expires_at > ?', Time.current) }

  def expired?
    expires_at < Time.current
  end

  def acceptable?
    pending? && !expired?
  end

  def accept!(user)
    return false unless acceptable?

    transaction do
      employee = restaurant.employees.create!(
        user: user,
        name: user.name.presence || email.split('@').first,
        eid: generate_eid,
        role: role,
        status: :active,
        email: email,
      )

      update!(status: :accepted, accepted_at: Time.current)
      employee
    end
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiry
    self.expires_at ||= 7.days.from_now
  end

  def generate_eid
    "INV-#{SecureRandom.hex(4).upcase}"
  end
end
