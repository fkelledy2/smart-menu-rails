# frozen_string_literal: true

require 'test_helper'

class ProvisionUnclaimedRestaurantJobTest < ActiveSupport::TestCase
  def build_discovered_without_restaurant(name: "DR #{SecureRandom.hex(4)}")
    dr = DiscoveredRestaurant.new(
      name: name,
      city_name: 'Dublin',
      google_place_id: "gp_prov_#{SecureRandom.hex(6)}",
      status: :pending,
      metadata: {},
    )
    dr.save!(validate: false)
    dr
  end

  def setup
    @user = users(:one)
    @admin_user = users(:two)
  end

  test 'does not raise when discovered restaurant already has a restaurant_id' do
    dr = build_discovered_without_restaurant
    restaurant = Restaurant.create!(
      user: @user,
      name: "Already Provisioned #{SecureRandom.hex(4)}",
      currency: 'USD',
      status: :active,
      capacity: 1,
    )
    dr.update_column(:restaurant_id, restaurant.id)

    assert_nothing_raised do
      ProvisionUnclaimedRestaurantJob.new.perform(
        discovered_restaurant_id: dr.id,
        provisioning_user_id: @user.id,
      )
    end
  end

  test 'creates a new restaurant from discovered restaurant when no restaurant_id exists' do
    dr = build_discovered_without_restaurant(name: 'Provisionable Place')

    # Stub DemoMenuService to avoid file I/O
    DemoMenuService.stub(:attach_demo_menu_to_restaurant!, nil) do
      # Stub DiscoveredRestaurantRestaurantSyncService to avoid full sync
      fake_sync = Object.new
      fake_sync.define_singleton_method(:sync!) { true }
      DiscoveredRestaurantRestaurantSyncService.stub(:new, ->(**_kwargs) { fake_sync }) do
        ProvisionUnclaimedRestaurantJob.new.perform(
          discovered_restaurant_id: dr.id,
          provisioning_user_id: @user.id,
        )
      end
    end

    dr.reload
    assert_not_nil dr.restaurant_id
    restaurant = Restaurant.find(dr.restaurant_id)
    assert_equal 'Provisionable Place', restaurant.name
    assert_equal :unclaimed.to_s, restaurant.claim_status
  end

  test 'returns nil without error when discovered restaurant does not exist' do
    result = nil
    assert_nothing_raised do
      result = ProvisionUnclaimedRestaurantJob.new.perform(
        discovered_restaurant_id: -999_999,
        provisioning_user_id: @user.id,
      )
    end
    assert_nil result
  end

  test 'returns nil without error when user does not exist' do
    dr = build_discovered_without_restaurant

    result = nil
    assert_nothing_raised do
      result = ProvisionUnclaimedRestaurantJob.new.perform(
        discovered_restaurant_id: dr.id,
        provisioning_user_id: -999_999,
      )
    end
    assert_nil result
  ensure
    dr&.destroy!
  end

  test 'enqueues asynchronously without raising' do
    assert_nothing_raised do
      ProvisionUnclaimedRestaurantJob.perform_later(
        discovered_restaurant_id: 1,
        provisioning_user_id: 1,
      )
    end
  end
end
