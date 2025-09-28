class Tablesetting < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :restaurant

  # Enums
  enum :status, {
    free: 0,
    occupied: 1,
    archived: 2,
  }

  enum :tabletype, {
    indoor: 1,
    outdoor: 2,
  }

  # Validations
  validates :tabletype, presence: true
  validates :name, presence: true
  validates :capacity, presence: true, numericality: { only_integer: true }
  validates :status, presence: true

  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id

  # Cache associations
  cache_belongs_to :restaurant
end
