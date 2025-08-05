class Ordrparticipant < ApplicationRecord
  include IdentityCache
  
  # Standard ActiveRecord associations
  belongs_to :employee, optional: true
  belongs_to :ordr, optional: false
  belongs_to :ordritem, optional: true
  has_many :ordrparticipant_allergyn_filters, dependent: :destroy
  has_many :allergyns, through: :ordrparticipant_allergyn_filters

  # Enums
  enum role: {
    customer: 0,
    staff: 1
  }

  # Validations
  validates :ordr, presence: true
  validates :sessionid, presence: true
  validates :preferredlocale, presence: false
  
  # IdentityCache configuration
  cache_index :id
  cache_index :employee_id
  cache_index :ordr_id
  cache_index :ordritem_id
  
  # Cache associations
  # Note: Cannot cache through associations (has_many :through) with IdentityCache
  # Only caching direct associations
  cache_belongs_to :employee
  cache_belongs_to :ordr
  cache_belongs_to :ordritem
  cache_has_many :ordrparticipant_allergyn_filters, embed: :ids
  
  # Allergyns are accessed through ordrparticipant_allergyn_filters
  # This is a has_many :through association which can't be directly cached
end
