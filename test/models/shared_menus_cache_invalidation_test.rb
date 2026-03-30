require 'test_helper'

class SharedMenusCacheInvalidationTest < ActiveSupport::TestCase
  def setup
    @restaurant_a = restaurants(:one)
    @restaurant_b = restaurants(:two)
    @menu = menus(:shared_cache_menu)
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
