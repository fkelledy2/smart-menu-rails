class Ordritem < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :ordr
  belongs_to :menuitem
  has_one :ordrparticipant
  has_many :ordritemnotes, dependent: :destroy

  # Enums
  enum :status, {
    opened: 0,
    ordered: 20,
    preparing: 22,
    ready: 24,
    delivered: 25,
    billrequested: 30,
    paid: 35,
    closed: 40,
  }

  # IdentityCache configuration
  cache_index :id
  cache_index :ordr_id
  cache_index :menuitem_id

  # Cache associations
  cache_belongs_to :ordr
  cache_belongs_to :menuitem
  cache_has_one :ordrparticipant, embed: :id
end
