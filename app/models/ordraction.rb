class Ordraction < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :ordrparticipant, optional: false
  belongs_to :ordr, optional: false
  belongs_to :ordritem, optional: true

  # Enums
  enum :action, {
    participate: 0,
    openorder: 1,
    additem: 2,
    removeitem: 3,
    requestbill: 4,
    closeorder: 5,
  }

  # Validations
  validates :action, presence: true

  # IdentityCache configuration
  cache_index :id
  cache_index :ordrparticipant_id
  cache_index :ordr_id
  cache_index :ordritem_id

  # Cache associations
  cache_belongs_to :ordrparticipant
  cache_belongs_to :ordr
  cache_belongs_to :ordritem
end
