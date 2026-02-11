class ResyncApprovedDiscoveredRestaurantsJob < ApplicationJob
  queue_as :default

  def perform(provisioning_user_id: nil)
    provisioning_user = provisioning_user_id.present? ? User.find_by(id: provisioning_user_id) : nil

    DiscoveredRestaurant.where(status: DiscoveredRestaurant.statuses[:approved]).find_each do |discovered|
      if discovered.restaurant_id.present?
        SyncDiscoveredRestaurantToRestaurantJob.perform_later(discovered_restaurant_id: discovered.id)
      else
        next if provisioning_user.blank?

        ProvisionUnclaimedRestaurantJob.perform_later(
          discovered_restaurant_id: discovered.id,
          provisioning_user_id: provisioning_user.id,
        )
      end
    end
  end
end
