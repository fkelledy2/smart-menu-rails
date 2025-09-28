class Menuavailability < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :menu

  # Enums
  enum :dayofweek, {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6,
  }

  # IdentityCache configuration
  cache_index :id
  cache_index :menu_id

  # Cache associations
  cache_belongs_to :menu

  def get_parent_restaurant
    menu&.restaurant
  end

  enum :status, {
    active: 0,
    inactive: 1,
  }
end
