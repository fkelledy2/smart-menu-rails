require 'test_helper'

class PerformanceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @ordr = ordrs(:one)
    @user = users(:one)
  end

  test "cache invalidation job processes without errors" do
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(
        order_id: @ordr.id,
        restaurant_id: @restaurant.id,
        user_id: @user.id
      )
    end
  end

  test "selective restaurant cache invalidation works" do
    # Test that selective invalidation doesn't raise errors
    assert_nothing_raised do
      AdvancedCacheService.invalidate_restaurant_caches_selectively(@restaurant.id)
    end
  end

  test "user cache invalidation with skip cascade works" do
    assert_nothing_raised do
      AdvancedCacheService.invalidate_user_caches(@user.id, skip_restaurant_cascade: true)
    end
  end

  test "tax calculation caching works" do
    # Create a controller instance to test the private method
    controller = OrdrsController.new
    
    # Test that tax calculation doesn't raise errors
    assert_nothing_raised do
      controller.send(:calculate_order_totals, @ordr)
    end
    
    # Verify the order totals are calculated
    assert @ordr.gross.present?
    assert @ordr.tax.present?
    assert @ordr.service.present?
  end

  test "advanced cache service handles errors gracefully" do
    # Test with invalid IDs to ensure error handling works
    assert_nothing_raised do
      AdvancedCacheService.invalidate_order_caches(999999)
      AdvancedCacheService.invalidate_restaurant_caches(999999)
      AdvancedCacheService.invalidate_user_caches(999999, skip_restaurant_cascade: true)
    end
  end

  test "cache invalidation job handles missing records gracefully" do
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(
        order_id: 999999,
        restaurant_id: 999999,
        user_id: 999999
      )
    end
  end
end
