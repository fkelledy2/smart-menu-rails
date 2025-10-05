class Inventory < ApplicationRecord
  include IdentityCache
  
  belongs_to :menuitem
  
  # IdentityCache configuration
  cache_index :id
  cache_index :menuitem_id
  cache_index :status
  
  # Cache associations
  cache_belongs_to :menuitem

  enum :status, {
    inactive: 0,
    active: 1,
    archived: 2,
  }

  validates :startinginventory, presence: true, numericality: { only_integer: true }
  validates :currentinventory, presence: true, numericality: { only_integer: true }
  validates :resethour, presence: true, numericality: { only_integer: true }
end
