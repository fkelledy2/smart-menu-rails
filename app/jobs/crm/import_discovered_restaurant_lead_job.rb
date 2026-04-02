# frozen_string_literal: true

module Crm
  # Creates a CrmLead from a DiscoveredRestaurant record.
  # Idempotent — skips silently if a lead already exists for this discovery.
  # Enqueued automatically when a new DiscoveredRestaurant is created.
  class ImportDiscoveredRestaurantLeadJob < ApplicationJob
    queue_as :crm

    def perform(discovered_restaurant_id:)
      dr = DiscoveredRestaurant.find_by(id: discovered_restaurant_id)
      return unless dr
      return if CrmLead.exists?(discovered_restaurant_id: dr.id)

      lead = CrmLead.create!(
        restaurant_name: dr.name,
        contact_email:   dr.preferred_email.presence,
        contact_phone:   dr.preferred_phone.presence,
        source:          discovery_source(dr),
        stage:           'new',
        discovered_restaurant_id: dr.id,
        last_activity_at: Time.current,
      )

      Crm::LeadAuditWriter.write(
        crm_lead: lead,
        event: 'lead_created',
        actor: nil,
        actor_type: 'system',
        metadata: {
          source:                   'discovered_restaurant',
          discovered_restaurant_id: dr.id,
          city:                     dr.city_name,
          google_place_id:          dr.google_place_id,
        },
      )
    end

    private

    def discovery_source(dr)
      dr.metadata&.dig('source').presence || 'google_places'
    end
  end
end
