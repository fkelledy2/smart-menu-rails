class Restaurantavailability < ApplicationRecord
  include IdentityCache
  
  # Standard ActiveRecord associations
  belongs_to :restaurant

  # Enums
  enum dayofweek: {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6
  }

  enum status: {
    open: 0,
    closed: 1
  }
  
  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id
  
  # Cache associations
  cache_belongs_to :restaurant
end
