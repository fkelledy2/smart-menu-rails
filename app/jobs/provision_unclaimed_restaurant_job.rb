class ProvisionUnclaimedRestaurantJob < ApplicationJob
  queue_as :default

  def perform(discovered_restaurant_id:, provisioning_user_id:)
    discovered = DiscoveredRestaurant.find(discovered_restaurant_id)
    user = User.find(provisioning_user_id)

    admin_user = User.find_by(email: 'admin@mellow.menu') || user

    return if discovered.restaurant_id.present?

    ActiveRecord::Base.transaction do
      restaurant = Restaurant.create!(
        user: admin_user,
        name: discovered.name,
        claim_status: :unclaimed,
        provisioned_by: :provisioned_by_system,
        source_url: discovered.website_url,
        preview_enabled: true,
        preview_published_at: Time.current,
        preview_indexable: false,
        ordering_enabled: false,
        payments_enabled: false,
        status: :inactive,
      )

      DiscoveredRestaurantRestaurantSyncService.new(
        discovered_restaurant: discovered,
        restaurant: restaurant,
      ).sync!

      discovered.update!(restaurant_id: restaurant.id)
    end

    true
  end
end
