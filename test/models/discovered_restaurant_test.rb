# frozen_string_literal: true

require 'test_helper'

class DiscoveredRestaurantTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def build_discovered(overrides = {})
    DiscoveredRestaurant.new({
      name: 'Test Bistro',
      city_name: 'Dublin',
      google_place_id: "gp_#{SecureRandom.hex(6)}",
      status: :pending,
      metadata: {},
    }.merge(overrides))
    # Skip after_commit callbacks to avoid job enqueues during test setup
  end

  def save_discovered(overrides = {})
    dr = build_discovered(overrides)
    dr.save!(validate: false)
    dr
  end

  # =========================================================================
  # validations
  # =========================================================================

  test 'is invalid without name' do
    dr = build_discovered(name: nil)
    assert_not dr.valid?
    assert dr.errors[:name].any?
  end

  test 'is invalid without city_name' do
    dr = build_discovered(city_name: nil)
    assert_not dr.valid?
    assert dr.errors[:city_name].any?
  end

  test 'is invalid without google_place_id' do
    dr = build_discovered(google_place_id: nil)
    assert_not dr.valid?
    assert dr.errors[:google_place_id].any?
  end

  # =========================================================================
  # enum
  # =========================================================================

  test 'status enum has pending approved rejected blacklisted' do
    %i[pending approved rejected blacklisted].each do |s|
      dr = build_discovered(status: s)
      assert_equal s.to_s, dr.status
    end
  end

  # =========================================================================
  # place_details
  # =========================================================================

  test 'place_details returns empty hash when metadata is empty' do
    dr = build_discovered(metadata: {})
    assert_equal({}, dr.place_details)
  end

  test 'place_details returns nested place_details from metadata' do
    dr = build_discovered(metadata: { 'place_details' => { 'types' => ['restaurant'] } })
    assert_equal({ 'types' => ['restaurant'] }, dr.place_details)
  end

  test 'place_details returns empty hash when metadata is not a hash' do
    dr = build_discovered
    dr.metadata = 'bad_value'
    assert_equal({}, dr.place_details)
  end

  # =========================================================================
  # inferred address component helpers
  # =========================================================================

  test 'inferred_country_code extracts country short_name from address_components' do
    place_details = {
      'address_components' => [
        { 'types' => ['country'], 'short_name' => 'IE', 'long_name' => 'Ireland' },
      ],
    }
    dr = build_discovered(metadata: { 'place_details' => place_details })
    assert_equal 'IE', dr.inferred_country_code
  end

  test 'inferred_country_code returns nil when no country component present' do
    dr = build_discovered(metadata: { 'place_details' => { 'address_components' => [] } })
    assert_nil dr.inferred_country_code
  end

  test 'inferred_postcode extracts postal_code from address_components' do
    place_details = {
      'address_components' => [
        { 'types' => ['postal_code'], 'long_name' => 'D02 XY12', 'short_name' => 'D02 XY12' },
      ],
    }
    dr = build_discovered(metadata: { 'place_details' => place_details })
    assert_equal 'D02 XY12', dr.inferred_postcode
  end

  test 'inferred_city returns locality long_name' do
    place_details = {
      'address_components' => [
        { 'types' => ['locality'], 'long_name' => 'Dublin', 'short_name' => 'Dublin' },
      ],
    }
    dr = build_discovered(metadata: { 'place_details' => place_details })
    assert_equal 'Dublin', dr.inferred_city
  end

  test 'inferred_address1 combines street_number and route' do
    place_details = {
      'address_components' => [
        { 'types' => ['street_number'], 'long_name' => '42', 'short_name' => '42' },
        { 'types' => ['route'], 'long_name' => 'Main Street', 'short_name' => 'Main St' },
      ],
    }
    dr = build_discovered(metadata: { 'place_details' => place_details })
    assert_equal '42 Main Street', dr.inferred_address1
  end

  # =========================================================================
  # effective_country_code
  # =========================================================================

  test 'effective_country_code returns explicit country_code when present' do
    dr = build_discovered(country_code: 'GB')
    assert_equal 'GB', dr.effective_country_code
  end

  test 'effective_country_code falls back to inferred_country_code when explicit is nil' do
    place_details = {
      'address_components' => [
        { 'types' => ['country'], 'short_name' => 'FR', 'long_name' => 'France' },
      ],
    }
    dr = build_discovered(metadata: { 'place_details' => place_details }, country_code: nil)
    assert_equal 'FR', dr.effective_country_code
  end

  # =========================================================================
  # suggested_currency
  # =========================================================================

  test 'suggested_currency returns explicit currency when set' do
    dr = build_discovered(currency: 'JPY')
    assert_equal 'JPY', dr.suggested_currency
  end

  test 'suggested_currency infers from country when currency not set' do
    dr = build_discovered(currency: nil, country_code: 'IE')
    # IE → EUR via CountryCurrencyInference
    currency = dr.suggested_currency
    assert_equal 'EUR', currency
  end

  test 'suggested_currency returns nil gracefully when no country info present' do
    dr = build_discovered(currency: nil, country_code: nil, metadata: {})
    assert_nil dr.suggested_currency
  end

  # =========================================================================
  # CRM lead import callback
  # =========================================================================

  test 'enqueues ImportDiscoveredRestaurantLeadJob when status transitions to approved' do
    dr = save_discovered(status: :pending)

    assert_enqueued_with(job: Crm::ImportDiscoveredRestaurantLeadJob) do
      dr.update!(status: :approved)
    end
  end

  test 'does not enqueue ImportDiscoveredRestaurantLeadJob on create' do
    assert_no_enqueued_jobs(only: Crm::ImportDiscoveredRestaurantLeadJob) do
      DiscoveredRestaurant.create!(
        name: 'New Place',
        city_name: 'Cork',
        google_place_id: "gp_#{SecureRandom.hex(6)}",
        status: :pending,
        metadata: {},
      )
    end
  end

  test 'does not enqueue ImportDiscoveredRestaurantLeadJob when updating non-status fields' do
    dr = save_discovered(status: :pending)

    assert_no_enqueued_jobs(only: Crm::ImportDiscoveredRestaurantLeadJob) do
      dr.update!(description: 'Updated description')
    end
  end

  test 'does not enqueue ImportDiscoveredRestaurantLeadJob when status changes to rejected' do
    dr = save_discovered(status: :pending)

    assert_no_enqueued_jobs(only: Crm::ImportDiscoveredRestaurantLeadJob) do
      dr.update!(status: :rejected)
    end
  end

  test 'does not enqueue ImportDiscoveredRestaurantLeadJob when already approved and re-saved' do
    dr = save_discovered(status: :approved)

    assert_no_enqueued_jobs(only: Crm::ImportDiscoveredRestaurantLeadJob) do
      dr.update!(description: 'Still approved but no status change')
    end
  end

  # =========================================================================
  # SYNC_TO_RESTAURANT_FIELDS constant
  # =========================================================================

  test 'SYNC_TO_RESTAURANT_FIELDS is frozen and includes expected fields' do
    assert DiscoveredRestaurant::SYNC_TO_RESTAURANT_FIELDS.frozen?
    assert_includes DiscoveredRestaurant::SYNC_TO_RESTAURANT_FIELDS, 'name'
    assert_includes DiscoveredRestaurant::SYNC_TO_RESTAURANT_FIELDS, 'google_place_id'
  end
end
