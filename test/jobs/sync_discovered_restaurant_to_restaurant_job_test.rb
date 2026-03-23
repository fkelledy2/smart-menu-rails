# frozen_string_literal: true

require 'test_helper'

class SyncDiscoveredRestaurantToRestaurantJobTest < ActiveSupport::TestCase
  def build_discovered_with_restaurant
    user = users(:one)
    restaurant = Restaurant.create!(
      user: user,
      name: "SyncJob Test #{SecureRandom.hex(4)}",
      currency: 'USD',
      status: :active,
      capacity: 5,
    )

    dr = DiscoveredRestaurant.new(
      name: 'Synced Bistro',
      city_name: 'Berlin',
      google_place_id: "gp_sync_#{SecureRandom.hex(4)}",
      status: :pending,
      restaurant: restaurant,
      metadata: {},
    )
    dr.save!(validate: false)

    [dr, restaurant]
  end

  test 'calls sync! on the service when discovered restaurant and restaurant both exist' do
    dr, restaurant = build_discovered_with_restaurant
    synced = false

    # Stub the service at the class level to intercept instantiation
    fake_service = Object.new
    fake_service.define_singleton_method(:sync!) { synced = true }

    DiscoveredRestaurantRestaurantSyncService.stub(:new, ->(**_kwargs) { fake_service }) do
      SyncDiscoveredRestaurantToRestaurantJob.new.perform(discovered_restaurant_id: dr.id)
    end

    assert synced
  end

  test 'does nothing when discovered restaurant does not exist' do
    assert_nothing_raised do
      SyncDiscoveredRestaurantToRestaurantJob.new.perform(discovered_restaurant_id: -999_999)
    end
  end

  test 'does nothing when discovered restaurant has no linked restaurant' do
    dr = DiscoveredRestaurant.new(
      name: 'No Restaurant',
      city_name: 'Dublin',
      google_place_id: "gp_no_r_#{SecureRandom.hex(4)}",
      status: :pending,
      metadata: {},
    )
    dr.save!(validate: false)

    synced = false
    fake_service = Object.new
    fake_service.define_singleton_method(:sync!) { synced = true }

    DiscoveredRestaurantRestaurantSyncService.stub(:new, ->(**_kwargs) { fake_service }) do
      SyncDiscoveredRestaurantToRestaurantJob.new.perform(discovered_restaurant_id: dr.id)
    end

    assert_equal false, synced
  end

  test 'enqueues asynchronously without raising' do
    assert_nothing_raised do
      SyncDiscoveredRestaurantToRestaurantJob.perform_later(discovered_restaurant_id: 1)
    end
  end
end
