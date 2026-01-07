class RestaurantMenu < ApplicationRecord
  belongs_to :restaurant
  belongs_to :menu

  after_commit :invalidate_restaurant_caches, on: %i[create update destroy]

  enum :status, {
    inactive: 0,
    active: 1,
    archived: 2,
  }

  enum :availability_state, {
    available: 0,
    unavailable: 1,
  }

  validates :status, presence: true
  validates :availability_state, presence: true

  validates :menu_id, uniqueness: { scope: :restaurant_id }

  def effective_available?
    return availability_state == 'available' if availability_override_enabled

    true
  end

  private

  def invalidate_restaurant_caches
    AdvancedCacheService.invalidate_restaurant_caches(restaurant_id)
  rescue StandardError
    nil
  end
end
