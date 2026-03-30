# frozen_string_literal: true

# Tracks customers waiting for a table at a restaurant.
# Status lifecycle: waiting -> notified -> seated (terminal success)
#                  waiting -> cancelled | no_show (terminal abandon)
class CustomerWaitQueue < ApplicationRecord
  include IdentityCache

  STATUSES = %w[waiting notified seated cancelled no_show].freeze
  STANDARD_PARTY_SIZES = [2, 4, 6, 8].freeze
  DEFAULT_WAIT_MINUTES = 30

  belongs_to :restaurant
  belongs_to :tablesetting, optional: true

  validates :customer_name, presence: true, length: { maximum: 100 }
  validates :customer_phone, format: {
    with: /\A[\d\s+\-().]{7,20}\z/,
    message: 'must be a valid phone number',
    allow_blank: true,
  }
  validates :party_size, presence: true,
                         numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 50 }
  validates :joined_queue_at, presence: true
  validates :queue_position, presence: true,
                             numericality: { only_integer: true, greater_than: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active, -> { where(status: %w[waiting notified]) }
  scope :waiting_only, -> { where(status: 'waiting') }
  scope :for_today, -> { where(joined_queue_at: Time.current.beginning_of_day..) }
  scope :by_position, -> { order(queue_position: :asc) }

  cache_index :id
  cache_index :restaurant_id

  def waiting?
    status == 'waiting'
  end

  def notified?
    status == 'notified'
  end

  def seated?
    status == 'seated'
  end

  def cancelled?
    status == 'cancelled'
  end

  def no_show?
    status == 'no_show'
  end

  def terminal?
    %w[seated cancelled no_show].include?(status)
  end

  def active?
    %w[waiting notified].include?(status)
  end
end
