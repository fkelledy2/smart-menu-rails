class Testimonial < ApplicationRecord
  include IdentityCache

  # Enums
  enum :status, {
    unapproved: 0,
    approved: 1,
  }

  # Standard ActiveRecord associations
  belongs_to :user
  belongs_to :restaurant

  # Validations

  # IdentityCache configuration
  cache_index :id
  cache_index :user_id
  cache_index :restaurant_id

  # Cache associations
  cache_belongs_to :user
  cache_belongs_to :restaurant
end
