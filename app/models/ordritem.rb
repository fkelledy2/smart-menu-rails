class Ordritem < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :ordr, touch: true
  belongs_to :menuitem
  belongs_to :ordr_station_ticket, optional: true
  has_one :ordrparticipant
  has_many :ordritemnotes, dependent: :destroy
  has_many :ordritem_events, dependent: :destroy

  # Enums
  enum :status, {
    opened: 0,
    removed: 10,
    ordered: 20,
    preparing: 22,
    ready: 24,
    delivered: 25,
    billrequested: 30,
    paid: 35,
    closed: 40,
  }

  # Fulfillment tracking — independent of the lifecycle status enum above.
  # Use prefix: to avoid method name collisions (e.g. fulfillment_pending?, station_kitchen?).
  enum :fulfillment_status, {
    pending: 0,
    preparing: 1,
    ready: 2,
    collected: 3,
  }, prefix: :fulfillment

  enum :station, {
    kitchen: 0,
    bar: 1,
  }, prefix: :station

  before_validation :ensure_line_key, on: :create

  validates :line_key, presence: true
  validates :quantity, numericality: { greater_than: 0, less_than_or_equal_to: 99, only_integer: true }

  def total_price
    (ordritemprice || 0.0) * (quantity || 1)
  end

  def increase_quantity(amount = 1)
    self.quantity = [quantity + amount, 99].min
    save
  end

  def decrease_quantity(amount = 1)
    new_qty = quantity - amount
    if new_qty <= 0
      self.status = :removed
      self.ordritemprice = 0.0
      self.quantity = 1
    else
      self.quantity = new_qty
    end
    save
  end

  # IdentityCache configuration
  cache_index :id
  cache_index :ordr_id
  cache_index :menuitem_id

  # Cache associations
  cache_belongs_to :ordr
  cache_belongs_to :menuitem
  cache_has_one :ordrparticipant, embed: :id

  private

  def ensure_line_key
    self.line_key = SecureRandom.uuid if line_key.blank?
  end
end
