# frozen_string_literal: true

require 'test_helper'

class DiscoveredRestaurantRestaurantSyncServiceTest < ActiveSupport::TestCase
  # Build a minimal DiscoveredRestaurant that can be saved without triggering
  # the after_commit :enqueue_restaurant_sync_if_needed callback.
  def build_discovered(overrides = {})
    attrs = {
      name: 'Test Bistro',
      city_name: 'Dublin',
      google_place_id: "gp_#{SecureRandom.hex(4)}",
      status: :pending,
      metadata: {},
    }.merge(overrides)

    dr = DiscoveredRestaurant.new(attrs)
    # Skip callbacks to avoid background-job enqueue during test setup
    dr.save!(validate: false)
    dr
  end

  def build_restaurant(country: nil)
    user = users(:one)
    Restaurant.create!(
      user: user,
      name: "SyncTest #{SecureRandom.hex(4)}",
      currency: 'USD',
      country: country,
      status: :active,
      capacity: 10,
    )
  end

  # =========================================================================
  # sync_attributes
  # =========================================================================

  test 'sync_attributes returns name from discovered restaurant' do
    dr = build_discovered(name: 'Le Jardin')
    restaurant = build_restaurant

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: dr,
      restaurant: restaurant,
    )

    attrs = service.sync_attributes
    assert_equal 'Le Jardin', attrs[:name]
  end

  test 'sync_attributes includes google_place_id' do
    dr = build_discovered(google_place_id: 'ChIJtestplace')
    restaurant = build_restaurant

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: dr,
      restaurant: restaurant,
    )

    attrs = service.sync_attributes
    assert_equal 'ChIJtestplace', attrs[:google_place_id]
  end

  test 'sync_attributes omits nil values (compact)' do
    dr = build_discovered(name: 'Cafe Null')
    restaurant = build_restaurant

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: dr,
      restaurant: restaurant,
    )

    attrs = service.sync_attributes
    attrs.each_value do |v|
      assert_not_nil v, 'sync_attributes should not contain nil values after compact'
    end
  end

  test 'sync_attributes does not overwrite existing restaurant city' do
    dr = build_discovered(city_name: 'Dublin')
    restaurant = build_restaurant
    restaurant.update_column(:city, 'Cork')

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: dr,
      restaurant: restaurant,
    )

    attrs = service.sync_attributes
    # city should be omitted since restaurant already has one
    assert_not attrs.key?(:city), 'city should not overwrite an existing restaurant city'
  end

  # =========================================================================
  # GOOGLE_DAY_TO_DAYOFWEEK constant
  # =========================================================================

  test 'GOOGLE_DAY_TO_DAYOFWEEK maps 0 to sunday and 6 to saturday' do
    mapping = DiscoveredRestaurantRestaurantSyncService::GOOGLE_DAY_TO_DAYOFWEEK
    assert_equal :sunday, mapping[0]
    assert_equal :saturday, mapping[6]
    assert_equal 7, mapping.size
  end

  # =========================================================================
  # COUNTRY_TO_LOCALE constant
  # =========================================================================

  test 'COUNTRY_TO_LOCALE maps IE to en and FR to fr' do
    mapping = DiscoveredRestaurantRestaurantSyncService::COUNTRY_TO_LOCALE
    assert_equal 'en', mapping['IE']
    assert_equal 'fr', mapping['FR']
    assert_equal 'de', mapping['DE']
    assert_equal 'ja', mapping['JP']
  end

  # =========================================================================
  # sync! — happy path
  # =========================================================================

  test 'sync! returns true on success' do
    dr = build_discovered(name: 'Synced Place', city_name: 'London')
    restaurant = build_restaurant

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: dr,
      restaurant: restaurant,
    )

    result = service.sync!
    assert_equal true, result
  end

  test 'sync! updates restaurant name' do
    dr = build_discovered(name: 'New Name Bistro', city_name: 'Paris')
    restaurant = build_restaurant

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: dr,
      restaurant: restaurant,
    )

    service.sync!

    restaurant.reload
    assert_equal 'New Name Bistro', restaurant.name
  end

  test 'sync! records last_synced_at in discovered_restaurant metadata' do
    dr = build_discovered(name: 'Metadata Test')
    restaurant = build_restaurant

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: dr,
      restaurant: restaurant,
    )

    service.sync!

    dr.reload
    assert dr.metadata.is_a?(Hash)
    assert dr.metadata['last_synced_at'].present?
  end

  test 'sync! returns false when sync_attributes is blank' do
    dr = build_discovered(name: 'Blank Attrs Test')
    restaurant = build_restaurant

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: dr,
      restaurant: restaurant,
    )

    service.stub(:sync_attributes, {}) do
      result = service.sync!
      assert_equal false, result
    end
  end

  # =========================================================================
  # sync_default_table! — creates table when none exists
  # =========================================================================

  test 'sync! creates a default table when restaurant has no tablesettings' do
    dr = build_discovered(name: 'Table Test')
    restaurant = build_restaurant
    # Ensure no tablesettings exist
    restaurant.tablesettings.destroy_all

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: dr,
      restaurant: restaurant,
    )

    service.sync!

    assert restaurant.tablesettings.reload.exists?
    table = restaurant.tablesettings.first
    assert_equal 'T1', table.name
    assert_equal 4, table.capacity
  end

  test 'sync! does not create a duplicate table when one already exists' do
    dr = build_discovered(name: 'Table Exists Test')
    restaurant = build_restaurant
    # Ensure at least one non-archived tablesetting exists
    restaurant.tablesettings.create!(
      name: 'Existing Table',
      status: :free,
      tabletype: :indoor,
      capacity: 2,
      sequence: 1,
    )

    table_count_before = restaurant.tablesettings.count

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: dr,
      restaurant: restaurant,
    )

    service.sync!

    assert_equal table_count_before, restaurant.tablesettings.reload.count
  end

  # =========================================================================
  # sync_default_locale! — creates locale from country
  # =========================================================================

  test 'sync! creates a default locale for IE country code' do
    dr = build_discovered(name: 'Locale IE Test')
    restaurant = build_restaurant(country: 'IE')
    restaurant.restaurantlocales.destroy_all

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: dr,
      restaurant: restaurant,
    )

    service.sync!

    restaurant.reload
    locale = restaurant.restaurantlocales.where.not(status: :archived).first
    assert_not_nil locale
    assert_equal 'en', locale.locale
    assert locale.dfault
  end

  test 'sync! skips locale creation when restaurant already has an active locale' do
    dr = build_discovered(name: 'Locale Skip Test')
    restaurant = build_restaurant(country: 'FR')
    # Pre-create a locale
    restaurant.restaurantlocales.create!(locale: 'fr', status: :active, dfault: true)

    locale_count_before = restaurant.restaurantlocales.count

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: dr,
      restaurant: restaurant,
    )

    service.sync!

    assert_equal locale_count_before, restaurant.restaurantlocales.reload.count
  end

  test 'sync! skips locale creation for unknown country codes' do
    dr = build_discovered(name: 'Unknown Country Test')
    restaurant = build_restaurant(country: 'XX')
    restaurant.restaurantlocales.destroy_all

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: dr,
      restaurant: restaurant,
    )

    service.sync!

    assert_equal 0, restaurant.restaurantlocales.reload.count
  end

  # =========================================================================
  # sync_opening_hours! — from place_details
  # =========================================================================

  test 'sync! creates restaurantavailabilities from opening_hours in place_details' do
    opening_hours = [
      { 'day' => 1, 'open_hour' => 9, 'open_min' => 0, 'close_hour' => 21, 'close_min' => 0 },
    ]
    dr = build_discovered(
      name: 'Hours Test',
      metadata: { 'place_details' => { 'opening_hours' => opening_hours } },
    )
    restaurant = build_restaurant
    restaurant.restaurantavailabilities.destroy_all
    # Make restaurant unclaimed so hours are written
    restaurant.stub(:unclaimed?, true) do
      service = DiscoveredRestaurantRestaurantSyncService.new(
        discovered_restaurant: dr,
        restaurant: restaurant,
      )

      service.sync!
    end

    monday_avail = restaurant.restaurantavailabilities.find_by(dayofweek: :monday)
    assert_not_nil monday_avail
    assert_equal :open, monday_avail.status.to_sym
    assert_equal 9, monday_avail.starthour
    assert_equal 21, monday_avail.endhour
  end

  test 'sync! marks unseen days as closed' do
    # Only provide Monday — all other days should be marked closed
    opening_hours = [
      { 'day' => 1, 'open_hour' => 10, 'open_min' => 0, 'close_hour' => 22, 'close_min' => 0 },
    ]
    dr = build_discovered(
      name: 'Closed Days Test',
      metadata: { 'place_details' => { 'opening_hours' => opening_hours } },
    )
    restaurant = build_restaurant
    restaurant.restaurantavailabilities.destroy_all

    restaurant.stub(:unclaimed?, true) do
      service = DiscoveredRestaurantRestaurantSyncService.new(
        discovered_restaurant: dr,
        restaurant: restaurant,
      )
      service.sync!
    end

    sunday_avail = restaurant.restaurantavailabilities.find_by(dayofweek: :sunday)
    assert_not_nil sunday_avail
    assert_equal :closed, sunday_avail.status.to_sym
  end
end
