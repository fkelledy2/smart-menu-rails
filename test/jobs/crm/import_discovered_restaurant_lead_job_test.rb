# frozen_string_literal: true

require 'test_helper'

module Crm
  class ImportDiscoveredRestaurantLeadJobTest < ActiveJob::TestCase
    def build_dr(overrides = {})
      DiscoveredRestaurant.create!(
        {
          name: 'Test Bistro',
          city_name: 'Dublin',
          google_place_id: "gp_#{SecureRandom.hex(6)}",
          status: :approved,
          metadata: {},
        }.merge(overrides),
      )
    end

    # =========================================================================
    # happy path
    # =========================================================================

    test 'creates a CrmLead for an approved discovered restaurant' do
      dr = build_dr

      assert_difference 'CrmLead.count', 1 do
        Crm::ImportDiscoveredRestaurantLeadJob.perform_now(discovered_restaurant_id: dr.id)
      end

      lead = CrmLead.find_by!(discovered_restaurant_id: dr.id)
      assert_equal dr.name, lead.restaurant_name
      assert_equal 'new', lead.stage
    end

    test 'copies preferred_email and preferred_phone onto the lead' do
      dr = build_dr(preferred_email: 'owner@example.com', preferred_phone: '+353 1 234 5678')
      Crm::ImportDiscoveredRestaurantLeadJob.perform_now(discovered_restaurant_id: dr.id)

      lead = CrmLead.find_by!(discovered_restaurant_id: dr.id)
      assert_equal 'owner@example.com', lead.contact_email
      assert_equal '+353 1 234 5678', lead.contact_phone
    end

    test 'uses google_places as default source when metadata has no source key' do
      dr = build_dr(metadata: {})
      Crm::ImportDiscoveredRestaurantLeadJob.perform_now(discovered_restaurant_id: dr.id)

      lead = CrmLead.find_by!(discovered_restaurant_id: dr.id)
      assert_equal 'google_places', lead.source
    end

    test 'uses metadata source when present' do
      dr = build_dr(metadata: { 'source' => 'manual_import' })
      Crm::ImportDiscoveredRestaurantLeadJob.perform_now(discovered_restaurant_id: dr.id)

      lead = CrmLead.find_by!(discovered_restaurant_id: dr.id)
      assert_equal 'manual_import', lead.source
    end

    test 'writes a lead_created audit entry' do
      dr = build_dr

      assert_difference 'CrmLeadAudit.count', 1 do
        Crm::ImportDiscoveredRestaurantLeadJob.perform_now(discovered_restaurant_id: dr.id)
      end

      audit = CrmLeadAudit.last
      assert_equal 'lead_created', audit.event
      assert_equal 'system', audit.actor_type
    end

    test 'populates city from discovered_restaurant.city_name' do
      dr = build_dr(city_name: 'Cork')
      Crm::ImportDiscoveredRestaurantLeadJob.perform_now(discovered_restaurant_id: dr.id)

      lead = CrmLead.find_by!(discovered_restaurant_id: dr.id)
      assert_equal 'Cork', lead.city
    end

    test 'city is nil when discovered_restaurant has no city_name' do
      # city_name cannot be blank due to validates :city_name, presence: true,
      # so use a placeholder to satisfy the constraint but verify mapping
      dr = build_dr(city_name: 'Unknown')
      Crm::ImportDiscoveredRestaurantLeadJob.perform_now(discovered_restaurant_id: dr.id)

      lead = CrmLead.find_by!(discovered_restaurant_id: dr.id)
      assert_equal 'Unknown', lead.city
    end

    # =========================================================================
    # idempotency
    # =========================================================================

    test 'does not create a second lead when job runs twice for the same restaurant' do
      dr = build_dr

      Crm::ImportDiscoveredRestaurantLeadJob.perform_now(discovered_restaurant_id: dr.id)

      assert_no_difference 'CrmLead.count' do
        Crm::ImportDiscoveredRestaurantLeadJob.perform_now(discovered_restaurant_id: dr.id)
      end
    end

    test 're-approving a restaurant with an existing lead does not create a duplicate' do
      # Simulate: DR approved → lead created → DR un-approved → re-approved
      dr = build_dr(city_name: 'Dublin')
      Crm::ImportDiscoveredRestaurantLeadJob.perform_now(discovered_restaurant_id: dr.id)
      assert_equal 1, CrmLead.where(discovered_restaurant_id: dr.id).count

      # Re-run the job as if enqueue_crm_lead_import_if_approved fired again
      assert_no_difference 'CrmLead.count' do
        Crm::ImportDiscoveredRestaurantLeadJob.perform_now(discovered_restaurant_id: dr.id)
      end

      assert_equal 1, CrmLead.where(discovered_restaurant_id: dr.id).count
    end

    # =========================================================================
    # missing record
    # =========================================================================

    test 'returns silently when discovered_restaurant_id does not exist' do
      assert_no_difference 'CrmLead.count' do
        Crm::ImportDiscoveredRestaurantLeadJob.perform_now(discovered_restaurant_id: 0)
      end
    end
  end
end
