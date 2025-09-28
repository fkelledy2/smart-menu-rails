class Tax < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :restaurant

  # Enums
  enum :taxtype, {
    local: 0,
    state: 1,
    federal: 2,
    service: 3,
  }

  enum :status, {
    inactive: 0,
    active: 1,
    archived: 2,
  }

  # Validations
  validates :name, presence: true
  validates :taxpercentage, presence: true, numericality: { only_float: true }

  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id

  # Cache associations
  cache_belongs_to :restaurant
end
