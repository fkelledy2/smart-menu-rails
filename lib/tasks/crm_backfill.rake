# frozen_string_literal: true

namespace :crm do
  desc 'Backfill CRM leads for approved DiscoveredRestaurants that have no lead yet'
  task backfill_discovered_restaurant_leads: :environment do
    scope = DiscoveredRestaurant.approved.where(
      'NOT EXISTS (SELECT 1 FROM crm_leads WHERE crm_leads.discovered_restaurant_id = discovered_restaurants.id)',
    )

    total  = scope.count
    queued = 0

    puts "Found #{total} approved discovered restaurant(s) without a CRM lead."

    scope.find_each do |dr|
      Crm::ImportDiscoveredRestaurantLeadJob.perform_later(discovered_restaurant_id: dr.id)
      queued += 1
      print '.' if (queued % 10).zero?
    end

    puts "\nQueued #{queued} job(s). Done."
  end
end
