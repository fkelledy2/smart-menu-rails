require 'test_helper'

class SharedMenusCacheInvalidationTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @restaurant_a = restaurants(:one)

    @restaurant_b = Restaurant.create!(
      name: 'Cache Target Restaurant',
      description: 'Second restaurant owned by same user',
      address1: 'Addr',
      address2: 'Addr2',
      city: 'City',
      state: 'State',
      postcode: '00000',
      country: 'Country',
      status: :active,
      capacity: 10,
      currency: 'USD',
      user: @owner,
    )

    @menu = Menu.create!(
      restaurant: @restaurant_a,
      owner_restaurant: @restaurant_a,
      name: 'Cache Shared Menu',
      status: :active,
    )

    RestaurantMenu.create!(
      restaurant: @restaurant_a,
      menu: @menu,
      status: :active,
      availability_override_enabled: false,
      availability_state: :available,
    )

    # Create attachment to B
    RestaurantMenu.create!(
      restaurant: @restaurant_b,
      menu: @menu,
      status: :active,
      availability_override_enabled: false,
      availability_state: :available,
    )
  end

  test 'menu content invalidation fans out to all attached restaurants' do
    calls = []

    AdvancedCacheService.stub(:invalidate_restaurant_caches, ->(rid) { calls << rid }) do
      @menu.update!(description: 'Updated')
    end

    assert_includes calls, @restaurant_a.id
    assert_includes calls, @restaurant_b.id
  end

  test 'restaurant_menu setting change invalidates only that restaurant' do
    rm = RestaurantMenu.find_by!(restaurant_id: @restaurant_b.id, menu_id: @menu.id)

    calls = []
    AdvancedCacheService.stub(:invalidate_restaurant_caches, ->(rid) { calls << rid }) do
      rm.update!(availability_override_enabled: true, availability_state: :unavailable)
    end

    assert_equal [@restaurant_b.id], calls
  end
end
