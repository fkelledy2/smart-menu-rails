class Track < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :restaurant

  # Enums
  enum :status, {
    inactive: 0,
    active: 1,
    archived: 2,
  }

  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id

  # Cache associations
  cache_belongs_to :restaurant

  # Instance methods
  def trackNameToCamelCase
    name.delete(' ').gsub(/[^\w\s]/, '')
  end

  def sequenceImage
    "https://fakeimg.pl/128x128/ffffff/000?text=#{sequence}"
  end
end
