class ReceiptDelivery < ApplicationRecord
  belongs_to :ordr
  belongs_to :restaurant
  belongs_to :created_by_user, class_name: 'User', optional: true

  DELIVERY_METHODS = %w[email sms].freeze
  STATUSES = %w[pending sent failed].freeze
  MAX_RETRIES = 3

  validates :delivery_method, inclusion: { in: DELIVERY_METHODS }
  validates :status, inclusion: { in: STATUSES }
  validates :recipient_email, presence: true, if: -> { delivery_method == 'email' }
  validates :recipient_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :recipient_phone, presence: true, if: -> { delivery_method == 'sms' }
  validates :secure_token, presence: true, uniqueness: true
  validates :retry_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :ordr_id, presence: true
  validates :restaurant_id, presence: true

  before_validation :set_secure_token, on: :create

  scope :pending, -> { where(status: 'pending') }
  scope :sent, -> { where(status: 'sent') }
  scope :failed, -> { where(status: 'failed') }
  scope :retryable, -> { where(status: 'failed').where('retry_count < ?', MAX_RETRIES) }
  scope :for_ordr, ->(ordr_id) { where(ordr_id: ordr_id) }
  scope :recent, -> { order(created_at: :desc) }

  def mark_sent!
    update!(status: 'sent', sent_at: Time.current, error_message: nil)
  end

  def mark_failed!(message)
    update!(status: 'failed', error_message: message.to_s.truncate(500))
  end

  def increment_retry!
    increment!(:retry_count)
  end

  def retryable?
    status == 'failed' && retry_count < MAX_RETRIES
  end

  def sent?
    status == 'sent'
  end

  def pending?
    status == 'pending'
  end

  def failed?
    status == 'failed'
  end

  private

  def set_secure_token
    self.secure_token = SecureRandom.urlsafe_base64(32) if secure_token.blank?
  end
end
