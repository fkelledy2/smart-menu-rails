class SyncDiscoveredRestaurantToRestaurantJob < ApplicationJob
  queue_as :default

  def perform(discovered_restaurant_id:)
    discovered = DiscoveredRestaurant.find_by(id: discovered_restaurant_id)
    return if discovered.blank?
    return if discovered.restaurant.blank?

    DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: discovered,
      restaurant: discovered.restaurant,
    ).sync!
  end
end
