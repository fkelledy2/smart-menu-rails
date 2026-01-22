class Ordritem < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :ordr
  belongs_to :menuitem
  belongs_to :ordr_station_ticket, optional: true
  has_one :ordrparticipant
  has_many :ordritemnotes, dependent: :destroy

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

  before_validation :ensure_line_key, on: :create

  validates :line_key, presence: true

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
