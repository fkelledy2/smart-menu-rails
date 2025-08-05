class Ordritem < ApplicationRecord
  include IdentityCache
  
  # Standard ActiveRecord associations
  belongs_to :ordr
  belongs_to :menuitem
  has_one :ordrparticipant

  # Enums
  enum status: {
    added: 0,
    removed: 10,
    ordered: 20,
    prepared: 30,
    delivered: 40,
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
